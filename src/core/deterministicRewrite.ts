export interface RewriteRule {
  id: string;
  description: string;
  apply: (input: string) => string;
}

export interface RewriteDiffSegment {
  type: "equal" | "replace";
  before: string;
  after: string;
}

export interface RewriteDiff {
  changed: boolean;
  segments: RewriteDiffSegment[];
}

export interface DeterministicRewriteResult {
  text: string;
  appliedRules: string[];
}

interface PhraseReplacement {
  pattern: RegExp;
  replacement: string;
}

function makePhraseRule(
  id: string,
  description: string,
  replacements: PhraseReplacement[],
): RewriteRule {
  return {
    id,
    description,
    apply(input: string) {
      return replacements.reduce(
        (next, rule) => next.replace(rule.pattern, rule.replacement),
        input,
      );
    },
  };
}

const fillerRules = makePhraseRule(
  "filler-phrases",
  "Shortens common filler phrases and extra qualifiers.",
  [
    { pattern: /\bin order to\b/gi, replacement: "to" },
    { pattern: /\bdue to the fact that\b/gi, replacement: "because" },
    { pattern: /\bat this point in time\b/gi, replacement: "now" },
    { pattern: /\bin the event that\b/gi, replacement: "if" },
    {
      pattern: /\bthe system has the ability to\b/gi,
      replacement: "the system can",
    },
    {
      pattern: /\bit is important to note that\b/gi,
      replacement: "",
    },
    { pattern: /\bin order to achieve\b/gi, replacement: "to" },
  ],
);

const aiVocabularyRules = makePhraseRule(
  "ai-words",
  "Replaces inflated AI-leaning vocabulary with simpler wording.",
  [
    { pattern: /\bAdditionally,?/gi, replacement: "Also" },
    { pattern: /\bFurthermore,?/gi, replacement: "Also" },
    { pattern: /\bMoreover,?/gi, replacement: "Also" },
    { pattern: /\bcrucial\b/gi, replacement: "important" },
    { pattern: /\bvital\b/gi, replacement: "important" },
    { pattern: /\bpivotal\b/gi, replacement: "important" },
    { pattern: /\bstands as\b/gi, replacement: "is" },
    { pattern: /\bserves as\b/gi, replacement: "is" },
    { pattern: /\bboasts\b/gi, replacement: "has" },
    { pattern: /\bhighlighting\b/gi, replacement: "showing" },
    { pattern: /\bunderscoring\b/gi, replacement: "showing" },
    { pattern: /\bshowcasing\b/gi, replacement: "showing" },
    { pattern: /\benhancing\b/gi, replacement: "improving" },
    { pattern: /\bfostering\b/gi, replacement: "supporting" },
  ],
);

const redundantRules = makePhraseRule(
  "redundant-phrasing",
  "Removes repetitive AI pattern framing.",
  [
    { pattern: /\bat its core,?\s*/gi, replacement: "" },
    { pattern: /\bin essence\b/gi, replacement: "" },
    { pattern: /\bin that way\b/gi, replacement: "this way" },
    { pattern: /\bin the broader context\b/gi, replacement: "in context" },
    { pattern: /\bThe purpose of this is\b/gi, replacement: "This is" },
  ],
);

const collaborationRules = makePhraseRule(
  "collaborative-artifacts",
  "Removes chat-style transitions and support phrases.",
  [
    { pattern: /\bGreat question!?/gi, replacement: "" },
    { pattern: /\bI hope this helps!?/gi, replacement: "" },
    { pattern: /\bOf course!?/gi, replacement: "" },
    { pattern: /\bCertainly!?/gi, replacement: "" },
    { pattern: /\bYou're absolutely right,?\s*/gi, replacement: "" },
    { pattern: /\bHere is an overview of\b/gi, replacement: "" },
    {
      pattern: /\bHere is\b/gi,
      replacement: "",
    },
    {
      pattern:
        /\blet me know if you would like[^.!?\n]*[.!?]?\s*/gi,
      replacement: "",
    },
    {
      pattern: /\bWould you like me to expand[^.!?\n]*[.!?]?\s*/gi,
      replacement: "",
    },
  ],
);

const emDashRules = makePhraseRule(
  "em-dash-overuse",
  "Normalizes em dash style into comma-style rhythm.",
  [
    { pattern: /\s*—\s*/g, replacement: ", " },
    { pattern: /\s*--\s*/g, replacement: ", " },
  ],
);

const positiveConclusionRules = makePhraseRule(
  "generic-positive-conclusions",
  "Drops generic, vague AI-style concluding lines.",
  [
    {
      pattern: /\bIn conclusion,?\s*[^.!?\n]*[.!?]\s*/gi,
      replacement: "",
    },
    {
      pattern: /\bThe future looks bright\b[^.!?\n]*[.!?]?\s*/gi,
      replacement: "",
    },
    {
      pattern: /\bExciting times lie ahead\b[^.!?\n]*[.!?]?\s*/gi,
      replacement: "",
    },
    {
      pattern: /\bmajor step in the right direction\b[^.!?\n]*[.!?]?\s*/gi,
      replacement: "",
    },
  ],
);

const ruleOfThreePattern =
  /\b([^,.;!?]{1,80}),\s+([^,.;!?]{1,80}),\s+and\s+([^,.;!?]{1,80})([.,;!?]|\s|$)/g;

function isRuleOfThreePhrase(phrase: string): boolean {
  const text = phrase.trim();
  if (!text) {
    return false;
  }

  const words = text.split(/\s+/);
  if (text.length > 80 || words.length > 6) {
    return false;
  }

  return !/\b(is|are|was|were|have|has|had|can|could|would|should|might|if|when|while|because|therefore)\b/i.test(
    text,
  );
}

const ruleOfThree: RewriteRule = {
  id: "rule-of-three-compression",
  description: "Compresses obvious three-item list patterns where possible.",
  apply(input: string): string {
    return input.replace(
      ruleOfThreePattern,
      (_match, first, second, third, trailing) => {
        if (
          !isRuleOfThreePhrase(first) ||
          !isRuleOfThreePhrase(second) ||
          !isRuleOfThreePhrase(third)
        ) {
          return `${first.trim()}, ${second.trim()}, and ${third.trim()}${trailing}`;
        }
        return `${first.trim()} and ${second.trim()}${trailing}`;
      },
    );
  },
};

function normalizeTextSpacing(input: string): string {
  return input
    .replace(/\r\n/g, "\n")
    .replace(/[\u2018\u2019]/g, "'")
    .replace(/[\u201C\u201D]/g, '"')
    .replace(/\u00A0/g, " ")
    .replace(/[ \t]+/g, " ")
    .replace(/ +\n/g, "\n")
    .replace(/\n +/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .replace(/([.,!?;:])([^\s])/g, "$1 $2")
    .replace(/ +([.,!?;:])/g, "$1")
    .replace(/,\s*,/g, ", ")
    .replace(/\.{2,}/g, ".")
    .replace(/\s{2,}/g, " ")
    .trim();
}

export const deterministicRewriteRules: RewriteRule[] = [
  fillerRules,
  aiVocabularyRules,
  redundantRules,
  collaborationRules,
  emDashRules,
  ruleOfThree,
  positiveConclusionRules,
];

export function applyDeterministicRewrite(
  input: string,
): DeterministicRewriteResult {
  let text = input;
  const appliedRules: string[] = [];

  for (const rule of deterministicRewriteRules) {
    const next = rule.apply(text);
    if (next !== text) {
      appliedRules.push(rule.id);
      text = next;
    }
  }

  return {
    text: normalizeTextSpacing(text),
    appliedRules,
  };
}

export function deterministicRewrite(input: string): string {
  return applyDeterministicRewrite(input).text;
}

export function buildRewriteDiff(before: string, after: string): RewriteDiff {
  if (before === after) {
    return {
      changed: false,
      segments: [
        {
          type: "equal",
          before,
          after,
        },
      ],
    };
  }

  let prefixLength = 0;
  while (
    prefixLength < before.length &&
    prefixLength < after.length &&
    before[prefixLength] === after[prefixLength]
  ) {
    prefixLength += 1;
  }

  let beforeSuffix = before.length - 1;
  let afterSuffix = after.length - 1;
  while (
    beforeSuffix >= prefixLength &&
    afterSuffix >= prefixLength &&
    before[beforeSuffix] === after[afterSuffix]
  ) {
    beforeSuffix -= 1;
    afterSuffix -= 1;
  }

  const segments: RewriteDiffSegment[] = [];

  if (prefixLength > 0) {
    segments.push({
      type: "equal",
      before: before.slice(0, prefixLength),
      after: after.slice(0, prefixLength),
    });
  }

  segments.push({
    type: "replace",
    before: before.slice(prefixLength, beforeSuffix + 1),
    after: after.slice(prefixLength, afterSuffix + 1),
  });

  if (beforeSuffix + 1 < before.length) {
    segments.push({
      type: "equal",
      before: before.slice(beforeSuffix + 1),
      after: after.slice(afterSuffix + 1),
    });
  }

  return {
    changed: true,
    segments,
  };
}
