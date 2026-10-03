-- Going back forgets who was taken off what. A device that has not synced
-- since then keeps a set it can no longer read, which is how it was before.
DROP TABLE IF EXISTS collection_unshares;
DROP TABLE IF EXISTS set_unshares;
