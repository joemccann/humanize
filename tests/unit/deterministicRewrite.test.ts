import { strict as assert } from "node:assert";
import { test } from "node:test";

import { deterministicRewrite } from "../../src/core/deterministicRewrite";

test("deterministic rewrite strips filler phrases", () => {
  const input = "in order to test this sentence.";
  const output = deterministicRewrite(input);

  assert.equal(output, "to test this sentence.");
});


test("deterministic rewrite leaves stable text unchanged when no rule applies", () => {
  const input = "Simple statement with no obvious AI pattern.";
  const output = deterministicRewrite(input);

  assert.equal(output, input);
});
