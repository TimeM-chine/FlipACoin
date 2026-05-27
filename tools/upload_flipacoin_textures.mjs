#!/usr/bin/env node

import { readFile, readdir, writeFile } from "node:fs/promises";
import { basename, extname, join, resolve } from "node:path";

const ASSETS_API_URL = "https://apis.roblox.com/assets/v1";
const SUPPORTED_EXTENSIONS = new Set([".png", ".jpg", ".jpeg", ".bmp", ".tga"]);
const MIME_TYPES = {
	".png": "image/png",
	".jpg": "image/jpeg",
	".jpeg": "image/jpeg",
	".bmp": "image/bmp",
	".tga": "image/x-tga",
};

const args = parseArgs(process.argv.slice(2));
const rootDir = resolve(args.cwd || process.cwd());
const texturesDir = resolve(rootDir, args.textures || "textures");
const texturesLuaPath = resolve(rootDir, args.texturesLua || "src/ReplicatedStorage/configs/Textures.lua");
const manifestPath = resolve(rootDir, args.manifest || "output/roblox-texture-upload-result.json");
const dryRun = args.dryRun === true;
const assetType = args.assetType || process.env.ROBLOX_ASSET_TYPE || "Image";
const apiKey = process.env.ROBLOX_API_KEY;
const creator = getCreator();

const mappings = await discoverTextureMappings(texturesDir);
if (mappings.length === 0) {
	throw new Error(`No supported image files found in ${texturesDir}`);
}

console.log(`Found ${mappings.length} Flip A Coin texture files.`);
for (const mapping of mappings) {
	console.log(`${mapping.filePath} -> ${mapping.category}.${mapping.itemId}`);
}

if (dryRun) {
	console.log("Dry run complete. No files uploaded and Textures.lua was not changed.");
	process.exit(0);
}

if (!apiKey) {
	throw new Error("ROBLOX_API_KEY is required for upload.");
}
if (!creator) {
	throw new Error("Set ROBLOX_CREATOR_USER_ID or ROBLOX_CREATOR_GROUP_ID before uploading.");
}

const uploadResults = [];
for (const mapping of mappings) {
	const assetId = await uploadAsset(mapping, creator, assetType, apiKey);
	uploadResults.push({
		category: mapping.category,
		itemId: mapping.itemId,
		filePath: mapping.filePath,
		assetType,
		assetId,
		contentId: `rbxassetid://${assetId}`,
	});
	console.log(`Uploaded ${basename(mapping.filePath)} -> rbxassetid://${assetId}`);
}

await writeFile(manifestPath, `${JSON.stringify(uploadResults, null, 2)}\n`, "utf8");
await updateTexturesLua(texturesLuaPath, uploadResults);
console.log(`Wrote manifest: ${manifestPath}`);
console.log(`Updated: ${texturesLuaPath}`);

function parseArgs(rawArgs) {
	const parsed = {};
	for (let index = 0; index < rawArgs.length; index += 1) {
		const arg = rawArgs[index];
		if (arg === "--dry-run") {
			parsed.dryRun = true;
		} else if (arg.startsWith("--")) {
			const key = arg.slice(2).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());
			const value = rawArgs[index + 1];
			if (!value || value.startsWith("--")) {
				throw new Error(`Missing value for ${arg}`);
			}
			parsed[key] = value;
			index += 1;
		}
	}
	return parsed;
}

function getCreator() {
	if (process.env.ROBLOX_CREATOR_USER_ID) {
		return {
			userId: process.env.ROBLOX_CREATOR_USER_ID,
		};
	}
	if (process.env.ROBLOX_CREATOR_GROUP_ID) {
		return {
			groupId: process.env.ROBLOX_CREATOR_GROUP_ID,
		};
	}
	return undefined;
}

async function discoverTextureMappings(directory) {
	const entries = await readdir(directory, { withFileTypes: true });
	const mappings = [];
	for (const entry of entries) {
		if (!entry.isFile()) {
			continue;
		}

		const extension = extname(entry.name).toLowerCase();
		if (!SUPPORTED_EXTENSIONS.has(extension)) {
			continue;
		}

		const fileBaseName = basename(entry.name, extension);
		const mapping = getMappingForFileBaseName(fileBaseName);
		if (mapping) {
			mappings.push({
				...mapping,
				displayName: getDisplayName(mapping),
				filePath: join(directory, entry.name),
				mimeType: MIME_TYPES[extension],
			});
		}
	}

	mappings.sort((a, b) => {
		if (a.category !== b.category) {
			return a.category.localeCompare(b.category);
		}
		return getNaturalSortValue(a.itemId).localeCompare(getNaturalSortValue(b.itemId), undefined, { numeric: true });
	});
	return mappings;
}

function getMappingForFileBaseName(fileBaseName) {
	const coinMatch = fileBaseName.match(/^coin(\d+)$/i);
	if (coinMatch) {
		return {
			category: "coin",
			itemId: `coin${coinMatch[1]}`,
		};
	}

	const tableDecorationMatch = fileBaseName.match(/^TableDecoration(\d+)$/i);
	if (tableDecorationMatch) {
		return {
			category: "desk",
			itemId: tableDecorationMatch[1],
		};
	}

	const chairMatch = fileBaseName.match(/^(\d+)$/);
	if (chairMatch) {
		return {
			category: "chair",
			itemId: chairMatch[1],
		};
	}

	return undefined;
}

function getDisplayName(mapping) {
	if (mapping.category === "coin") {
		return `Flip A Coin ${mapping.itemId}`;
	}
	if (mapping.category === "desk") {
		return `Flip A Coin Desk ${mapping.itemId}`;
	}
	return `Flip A Coin Chair ${mapping.itemId}`;
}

function getNaturalSortValue(itemId) {
	return itemId.replace(/^coin/i, "");
}

async function uploadAsset(mapping, creator, uploadAssetType, uploadApiKey) {
	const fileBuffer = await readFile(mapping.filePath);
	const formData = new FormData();
	formData.append(
		"request",
		JSON.stringify({
			assetType: uploadAssetType,
			displayName: mapping.displayName,
			description: "Temporary Flip A Coin UI item icon uploaded by repository tooling.",
			creationContext: {
				creator,
			},
		}),
	);
	formData.append("fileContent", new Blob([fileBuffer], { type: mapping.mimeType }), basename(mapping.filePath));

	const createResponse = await fetch(`${ASSETS_API_URL}/assets`, {
		method: "POST",
		headers: {
			"x-api-key": uploadApiKey,
		},
		body: formData,
	});
	const createPayload = await readJsonResponse(createResponse);
	if (!createResponse.ok) {
		throw new Error(`Upload failed for ${mapping.filePath}: ${JSON.stringify(createPayload)}`);
	}

	const operation = await waitForOperation(createPayload, uploadApiKey);
	const assetId = getAssetIdFromOperation(operation);
	if (!assetId) {
		throw new Error(`Upload finished but asset id was not found for ${mapping.filePath}: ${JSON.stringify(operation)}`);
	}
	return assetId;
}

async function waitForOperation(createPayload, uploadApiKey) {
	const operationUrl = getOperationUrl(createPayload);
	if (!operationUrl) {
		return createPayload;
	}

	for (let attempt = 1; attempt <= 60; attempt += 1) {
		const response = await fetch(operationUrl, {
			headers: {
				"x-api-key": uploadApiKey,
			},
		});
		const payload = await readJsonResponse(response);
		if (!response.ok) {
			throw new Error(`Operation poll failed: ${JSON.stringify(payload)}`);
		}
		if (payload.done === true) {
			if (payload.error) {
				throw new Error(`Operation failed: ${JSON.stringify(payload.error)}`);
			}
			return payload;
		}
		await sleep(2000);
	}

	throw new Error(`Timed out waiting for operation ${operationUrl}`);
}

function getOperationUrl(payload) {
	const operationPath = payload.path || payload.name;
	if (!operationPath) {
		return undefined;
	}
	if (operationPath.startsWith("http://") || operationPath.startsWith("https://")) {
		return operationPath;
	}
	if (operationPath.startsWith("operations/")) {
		return `${ASSETS_API_URL}/${operationPath}`;
	}
	return `${ASSETS_API_URL}/operations/${operationPath}`;
}

function getAssetIdFromOperation(operation) {
	const candidates = [
		operation?.response?.assetId,
		operation?.response?.asset?.assetId,
		operation?.response?.id,
		operation?.metadata?.assetId,
		operation?.assetId,
	];
	for (const candidate of candidates) {
		if (candidate) {
			return String(candidate).match(/\d+/)?.[0];
		}
	}
	return undefined;
}

async function readJsonResponse(response) {
	const text = await response.text();
	if (!text) {
		return {};
	}
	try {
		return JSON.parse(text);
	} catch {
		return { raw: text };
	}
}

function sleep(milliseconds) {
	return new Promise((resolveSleep) => {
		setTimeout(resolveSleep, milliseconds);
	});
}

async function updateTexturesLua(filePath, results) {
	let source = await readFile(filePath, "utf8");
	for (const category of ["coin", "desk", "chair"]) {
		const replacements = results.filter((result) => result.category === category);
		if (replacements.length > 0) {
			source = replaceCategoryIcons(source, category, replacements);
		}
	}
	await writeFile(filePath, source, "utf8");
}

function replaceCategoryIcons(source, category, replacements) {
	const blockStart = source.indexOf(`\n\t${category} = {`);
	if (blockStart === -1) {
		throw new Error(`Could not find Textures.FlipACoinItems.${category} block in Textures.lua`);
	}

	const openBraceIndex = source.indexOf("{", blockStart);
	const closeBraceIndex = findMatchingBrace(source, openBraceIndex);
	let block = source.slice(openBraceIndex, closeBraceIndex + 1);

	for (const replacement of replacements) {
		const keyPattern = getLuaKeyPattern(replacement.itemId);
		const iconPattern = new RegExp(`(${keyPattern}\\s*=\\s*\\{\\s*icon\\s*=\\s*")rbxassetid://[^"]*(")`);
		const nextBlock = block.replace(iconPattern, `$1${replacement.contentId}$2`);
		if (nextBlock === block) {
			throw new Error(`Could not update ${category}.${replacement.itemId} in Textures.lua`);
		}
		block = nextBlock;
	}

	return `${source.slice(0, openBraceIndex)}${block}${source.slice(closeBraceIndex + 1)}`;
}

function getLuaKeyPattern(itemId) {
	if (/^[A-Za-z_][A-Za-z0-9_]*$/.test(itemId)) {
		return escapeRegExp(itemId);
	}
	return `\\["${escapeRegExp(itemId)}"\\]`;
}

function findMatchingBrace(source, openBraceIndex) {
	let depth = 0;
	let inString = false;
	let stringQuote = "";
	for (let index = openBraceIndex; index < source.length; index += 1) {
		const char = source[index];
		const previousChar = source[index - 1];
		if (inString) {
			if (char === stringQuote && previousChar !== "\\") {
				inString = false;
			}
			continue;
		}
		if (char === "\"" || char === "'") {
			inString = true;
			stringQuote = char;
			continue;
		}
		if (char === "{") {
			depth += 1;
		} else if (char === "}") {
			depth -= 1;
			if (depth === 0) {
				return index;
			}
		}
	}

	throw new Error("Could not find matching brace in Textures.lua");
}

function escapeRegExp(value) {
	return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
