// Shop collections for MongoDB → MongoDB migration.
//
// Covers:
// - ObjectId preservation
// - inferred relationships
// - users ⇄ teams circular references
// - 1:N / N:1 references
// - nullable references
// - repeated references
// - Decimal128 precision
// - booleans
// - integers
// - BSON dates
// - zero Decimal128 values
// - inactive documents
// - empty/unreferenced parent documents
//
// Matches the core shop_source fixture used by Piper's
// relational migration tests.

db = db.getSiblingDB("shop_source");
db.dropDatabase();
db = db.getSiblingDB("shop_source");

// ------------------------------------------------------------
// Teams
// ------------------------------------------------------------

db.teams.insertMany([
  {
    _id: ObjectId("aaaaaaaaaaaaaaaaaaaaaaaa"),
    name: "Alpha",
    userId: ObjectId("bbbbbbbbbbbbbbbbbbbbbbbb"),
  },
  {
    // Valid team with no user assigned.
    _id: ObjectId("abababababababababababab"),
    name: "Beta",
    userId: null,
  },
  {
    // Another valid team with no user assigned.
    // This also verifies that an otherwise unreferenced
    // parent document survives migration.
    _id: ObjectId("acacacacacacacacacacacac"),
    name: "Gamma",
    userId: null,
  },
]);

// ------------------------------------------------------------
// Users
// ------------------------------------------------------------

db.users.insertMany([
  {
    _id: ObjectId("bbbbbbbbbbbbbbbbbbbbbbbb"),
    name: "Ada",
    email: "ada@example.com",
    teamId: ObjectId("aaaaaaaaaaaaaaaaaaaaaaaa"),
  },
  {
    _id: ObjectId("cccccccccccccccccccccccc"),
    name: "Grace",
    email: "grace@example.com",
    teamId: ObjectId("aaaaaaaaaaaaaaaaaaaaaaaa"),
  },
  {
    // User with no team.
    _id: ObjectId("cdcdcdcdcdcdcdcdcdcdcdcd"),
    name: "Linus",
    email: "linus@example.com",
    teamId: null,
  },
]);

// ------------------------------------------------------------
// Products
// ------------------------------------------------------------

db.products.insertMany([
  {
    _id: ObjectId("dddddddddddddddddddddddd"),
    name: "Widget",
    price: NumberDecimal("9.99"),
    active: true,
  },
  {
    _id: ObjectId("eeeeeeeeeeeeeeeeeeeeeeee"),
    name: "Gadget",
    price: NumberDecimal("19.5000"),
    active: true,
  },
  {
    // Exercises Decimal128 precision beyond ordinary
    // two-decimal currency formatting.
    _id: ObjectId("dededededededededededede"),
    name: "Premium Box",
    price: NumberDecimal("123456789.1234"),
    active: true,
  },
  {
    // Exercises zero Decimal128 and false boolean values.
    _id: ObjectId("dfdfdfdfdfdfdfdfdfdfdfdf"),
    name: "Legacy Cable",
    price: NumberDecimal("0.00"),
    active: false,
  },
]);

// ------------------------------------------------------------
// Orders
// ------------------------------------------------------------

db.orders.insertMany([
  {
    _id: ObjectId("ffffffffffffffffffffffff"),
    userId: ObjectId("bbbbbbbbbbbbbbbbbbbbbbbb"),
    productId: ObjectId("dddddddddddddddddddddddd"),
    quantity: 2,
    createdAt: ISODate("2026-01-10T10:00:00Z"),
  },
  {
    _id: ObjectId("111111111111111111111111"),
    userId: ObjectId("cccccccccccccccccccccccc"),
    productId: ObjectId("eeeeeeeeeeeeeeeeeeeeeeee"),
    quantity: 1,
    createdAt: ISODate("2026-01-11T11:30:00Z"),
  },
  {
    // Same user as the first order, testing repeated references.
    _id: ObjectId("121212121212121212121212"),
    userId: ObjectId("bbbbbbbbbbbbbbbbbbbbbbbb"),
    productId: ObjectId("dededededededededededede"),
    quantity: 5,
    createdAt: ISODate("2026-01-15T09:15:00Z"),
  },
  {
    // Large integer quantity.
    _id: ObjectId("131313131313131313131313"),
    userId: ObjectId("cccccccccccccccccccccccc"),
    productId: ObjectId("dfdfdfdfdfdfdfdfdfdfdfdf"),
    quantity: 100,
    createdAt: ISODate("2026-02-01T14:00:00Z"),
  },
  {
    // Another repeated product reference.
    _id: ObjectId("141414141414141414141414"),
    userId: ObjectId("bbbbbbbbbbbbbbbbbbbbbbbb"),
    productId: ObjectId("dddddddddddddddddddddddd"),
    quantity: 1,
    createdAt: ISODate("2026-02-03T16:45:00Z"),
  },
]);
