const fileSystem = require("fs");
const sampleRoot = "/datasets/mongodb-sample-dataset";
const insertBatchSize = 100;
const jsonSuffix = ".json";

function readDocuments(filePath) {
  return fileSystem
    .readFileSync(filePath, "utf8")
    .split("\n")
    .filter((line) => line.trim() !== "")
    .map((line) => EJSON.parse(line));
}

function insertBatches(collection, documents) {
  let start = 0;
  while (start < documents.length) {
    const batch = documents.slice(start, start + insertBatchSize);
    collection.insertMany(batch, { ordered: false });
    start += insertBatchSize;
  }
}

function loadCollection(databaseName, collectionName, filePath) {
  const documents = readDocuments(filePath);
  const collection = db.getSiblingDB(databaseName).getCollection(collectionName);
  collection.drop();
  insertBatches(collection, documents);
  print(databaseName + "." + collectionName + " " + documents.length);
}

function loadDatabase(databaseName) {
  const directory = sampleRoot + "/" + databaseName;
  for (const fileName of fileSystem.readdirSync(directory)) {
    if (!fileName.endsWith(jsonSuffix)) {
      continue;
    }
    const collectionName = fileName.slice(0, -jsonSuffix.length);
    loadCollection(databaseName, collectionName, directory + "/" + fileName);
  }
}

function loadSamples() {
  for (const entry of fileSystem.readdirSync(sampleRoot)) {
    const fullPath = sampleRoot + "/" + entry;
    if (!fileSystem.statSync(fullPath).isDirectory()) {
      continue;
    }
    if (!entry.startsWith("sample_")) {
      continue;
    }
    loadDatabase(entry);
  }
}

loadSamples();
