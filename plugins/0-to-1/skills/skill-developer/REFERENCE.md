# Complete Reference Guide

Comprehensive configuration reference for Claude Code skills, trigger types, and ready-to-use patterns.

## Table of Contents

- [skill-rules.json Schema](#skill-rulesjson-schema)
  - [Complete TypeScript Schema](#complete-typescript-schema)
  - [Field Guide](#field-guide)
  - [Complete Examples](#complete-examples)
  - [Validation](#validation)
- [Trigger Types Guide](#trigger-types-guide)
  - [Keyword Triggers](#keyword-triggers-explicit)
  - [Intent Pattern Triggers](#intent-pattern-triggers-implicit)
  - [File Path Triggers](#file-path-triggers)
  - [Content Pattern Triggers](#content-pattern-triggers)
- [Pattern Library](#pattern-library)
  - [Intent Patterns (Regex)](#intent-patterns-regex)
  - [File Path Patterns (Glob)](#file-path-patterns-glob)
  - [Content Patterns (Regex)](#content-patterns-regex)
- [Testing Your Skills](#testing-your-skills)
  - [Test Commands](#test-commands)
  - [Best Practices](#best-practices-summary)

---

## skill-rules.json Schema

### File Location

**Path:** `.claude/skills/skill-rules.json`

This JSON file defines all skills and their trigger conditions for the auto-activation system.

### Complete TypeScript Schema

```typescript
interface SkillRules {
    version: string;
    skills: Record<string, SkillRule>;
}

interface SkillRule {
    type: 'guardrail' | 'domain';
    enforcement: 'block' | 'suggest' | 'warn';
    priority: 'critical' | 'high' | 'medium' | 'low';

    promptTriggers?: {
        keywords?: string[];
        intentPatterns?: string[];  // Regex strings
    };

    fileTriggers?: {
        pathPatterns: string[];     // Glob patterns
        pathExclusions?: string[];  // Glob patterns
        contentPatterns?: string[]; // Regex strings
        createOnly?: boolean;       // Only trigger on file creation
    };

    blockMessage?: string;  // For guardrails, {file_path} placeholder

    skipConditions?: {
        sessionSkillUsed?: boolean;      // Skip if used in session
        fileMarkers?: string[];          // e.g., ["@skip-validation"]
        envOverride?: string;            // e.g., "SKIP_DB_VERIFICATION"
    };
}
```

### Field Guide

#### Top Level

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Schema version (currently "1.0") |
| `skills` | object | Yes | Map of skill name → SkillRule |

#### SkillRule Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | "guardrail" (enforced) or "domain" (advisory) |
| `enforcement` | string | Yes | "block" (PreToolUse), "suggest" (UserPromptSubmit), or "warn" |
| `priority` | string | Yes | "critical", "high", "medium", or "low" |
| `promptTriggers` | object | Optional | Triggers for UserPromptSubmit hook |
| `fileTriggers` | object | Optional | Triggers for PreToolUse hook |
| `blockMessage` | string | Optional* | Required if enforcement="block". Use `{file_path}` placeholder |
| `skipConditions` | object | Optional | Escape hatches and session tracking |

*Required for guardrails

#### promptTriggers Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `keywords` | string[] | Optional | Exact substring matches (case-insensitive) |
| `intentPatterns` | string[] | Optional | Regex patterns for intent detection |

#### fileTriggers Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `pathPatterns` | string[] | Yes* | Glob patterns for file paths |
| `pathExclusions` | string[] | Optional | Glob patterns to exclude (e.g., test files) |
| `contentPatterns` | string[] | Optional | Regex patterns to match file content |
| `createOnly` | boolean | Optional | Only trigger when creating new files |

*Required if fileTriggers is present

#### skipConditions Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sessionSkillUsed` | boolean | Optional | Skip if skill already used this session |
| `fileMarkers` | string[] | Optional | Skip if file contains comment marker |
| `envOverride` | string | Optional | Environment variable name to disable skill |

### Complete Examples

#### Example: Guardrail Skill

Complete example of a blocking guardrail skill with all features:

```json
{
  "database-verification": {
    "type": "guardrail",
    "enforcement": "block",
    "priority": "critical",

    "promptTriggers": {
      "keywords": [
        "prisma",
        "database",
        "table",
        "column",
        "schema",
        "query",
        "migration"
      ],
      "intentPatterns": [
        "(add|create|implement).*?(user|login|auth|tracking|feature)",
        "(modify|update|change).*?(table|column|schema|field)",
        "database.*?(change|update|modify|migration)"
      ]
    },

    "fileTriggers": {
      "pathPatterns": [
        "**/schema.prisma",
        "**/migrations/**/*.sql",
        "database/src/**/*.ts",
        "form/src/**/*.ts",
        "email/src/**/*.ts"
      ],
      "pathExclusions": [
        "**/*.test.ts",
        "**/*.spec.ts"
      ],
      "contentPatterns": [
        "import.*[Pp]risma",
        "PrismaService",
        "prisma\\.",
        "\\.findMany\\(",
        "\\.create\\(",
        "\\.update\\(",
        "\\.delete\\("
      ]
    },

    "blockMessage": "⚠️ BLOCKED - Database Operation Detected\n\n📋 REQUIRED ACTION:\n1. Use Skill tool: 'database-verification'\n2. Verify ALL table and column names against schema\n3. Check database structure with DESCRIBE commands\n4. Then retry this edit\n\nReason: Prevent column name errors in Prisma queries\nFile: {file_path}\n\n💡 TIP: Add '// @skip-validation' comment to skip future checks",

    "skipConditions": {
      "sessionSkillUsed": true,
      "fileMarkers": [
        "@skip-validation"
      ],
      "envOverride": "SKIP_DB_VERIFICATION"
    }
  }
}
```

**Key Points for Guardrails:**
1. type: Must be "guardrail"
2. enforcement: Must be "block"
3. priority: Usually "critical" or "high"
4. blockMessage: Required, clear actionable steps
5. skipConditions: Session tracking prevents repeated nagging
6. fileTriggers: Usually has both path and content patterns
7. contentPatterns: Catch actual usage of technology

#### Example: Domain Skill

Complete example of a suggestion-based domain skill:

```json
{
  "project-catalog-developer": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",

    "promptTriggers": {
      "keywords": [
        "layout",
        "layout system",
        "grid",
        "toolbar",
        "column",
        "cell editor",
        "submission",
        "datagrid",
        "auto-save"
      ],
      "intentPatterns": [
        "(how does|explain|what is).*?(layout|grid|toolbar|submission)",
        "(add|create|modify).*?(toolbar|column|cell|editor)"
      ]
    },

    "fileTriggers": {
      "pathPatterns": [
        "frontend/src/features/submissions/**/*.tsx",
        "frontend/src/features/submissions/**/*.ts"
      ],
      "pathExclusions": [
        "**/*.test.tsx",
        "**/*.test.ts"
      ]
    }
  }
}
```

**Key Points for Domain Skills:**
1. type: Must be "domain"
2. enforcement: Usually "suggest"
3. priority: "high" or "medium"
4. blockMessage: Not needed (doesn't block)
5. skipConditions: Optional (less critical)
6. promptTriggers: Usually has extensive keywords
7. fileTriggers: May have only path patterns

### Validation

#### Check JSON Syntax

```bash
cat .claude/skills/skill-rules.json | jq .
```

If valid, jq will pretty-print the JSON. If invalid, it will show the error.

#### Common JSON Errors

**Trailing comma:**
```json
{
  "keywords": ["one", "two",]  // ❌ Trailing comma
}
```

**Missing quotes:**
```json
{
  type: "guardrail"  // ❌ Missing quotes on key
}
```

**Single quotes (invalid JSON):**
```json
{
  'type': 'guardrail'  // ❌ Must use double quotes
}
```

#### Validation Checklist

- [ ] JSON syntax valid (use `jq`)
- [ ] All skill names match SKILL.md filenames
- [ ] Guardrails have `blockMessage`
- [ ] Block messages use `{file_path}` placeholder
- [ ] Intent patterns are valid regex (test on regex101.com)
- [ ] File path patterns use correct glob syntax
- [ ] Content patterns escape special characters
- [ ] Priority matches enforcement level
- [ ] No duplicate skill names

---

## Trigger Types Guide

Complete reference for configuring skill triggers in Claude Code's skill auto-activation system.

### Keyword Triggers (Explicit)

#### How It Works

Case-insensitive substring matching in user's prompt.

#### Use For

Topic-based activation where user explicitly mentions the subject.

#### Configuration

```json
"promptTriggers": {
  "keywords": ["layout", "grid", "toolbar", "submission"]
}
```

#### Example

- User prompt: "how does the **layout** system work?"
- Matches: "layout" keyword
- Activates: `project-catalog-developer`

#### Best Practices

- Use specific, unambiguous terms
- Include common variations ("layout", "layout system", "grid layout")
- Avoid overly generic words ("system", "work", "create")
- Test with real prompts

---

### Intent Pattern Triggers (Implicit)

#### How It Works

Regex pattern matching to detect user's intent even when they don't mention the topic explicitly.

#### Use For

Action-based activation where user describes what they want to do rather than the specific topic.

#### Configuration

```json
"promptTriggers": {
  "intentPatterns": [
    "(create|add|implement).*?(feature|endpoint)",
    "(how does|explain).*?(layout|workflow)"
  ]
}
```

#### Examples

**Database Work:**
- User prompt: "add user tracking feature"
- Matches: `(add).*?(feature)`
- Activates: `database-verification`, `error-tracking`

**Component Creation:**
- User prompt: "create a dashboard widget"
- Matches: `(create).*?(component)` (if component in pattern)
- Activates: `frontend-dev-guidelines`

#### Best Practices

- Capture common action verbs: `(create|add|modify|build|implement)`
- Include domain-specific nouns: `(feature|endpoint|component|workflow)`
- Use non-greedy matching: `.*?` instead of `.*`
- Test patterns thoroughly with regex tester (https://regex101.com/)
- Don't make patterns too broad (causes false positives)
- Don't make patterns too specific (causes false negatives)

---

### File Path Triggers

#### How It Works

Glob pattern matching against the file path being edited.

#### Use For

Domain/area-specific activation based on file location in the project.

#### Configuration

```json
"fileTriggers": {
  "pathPatterns": [
    "frontend/src/**/*.tsx",
    "form/src/**/*.ts"
  ],
  "pathExclusions": [
    "**/*.test.ts",
    "**/*.spec.ts"
  ]
}
```

#### Glob Pattern Syntax

- `**` = Any number of directories (including zero)
- `*` = Any characters within a directory name
- Examples:
  - `frontend/src/**/*.tsx` = All .tsx files in frontend/src and subdirs
  - `**/schema.prisma` = schema.prisma anywhere in project
  - `form/src/**/*.ts` = All .ts files in form/src subdirs

#### Example

- File being edited: `frontend/src/components/Dashboard.tsx`
- Matches: `frontend/src/**/*.tsx`
- Activates: `frontend-dev-guidelines`

#### Best Practices

- Be specific to avoid false positives
- Use exclusions for test files: `**/*.test.ts`
- Consider subdirectory structure
- Test patterns with actual file paths
- Use narrower patterns when possible: `form/src/services/**` not `form/**`

---

### Content Pattern Triggers

#### How It Works

Regex pattern matching against the file's actual content (what's inside the file).

#### Use For

Technology-specific activation based on what the code imports or uses (Prisma, controllers, specific libraries).

#### Configuration

```json
"fileTriggers": {
  "contentPatterns": [
    "import.*[Pp]risma",
    "PrismaService",
    "\\.findMany\\(",
    "\\.create\\("
  ]
}
```

#### Examples

**Prisma Detection:**
- File contains: `import { PrismaService } from '@project/database'`
- Matches: `import.*[Pp]risma`
- Activates: `database-verification`

**Controller Detection:**
- File contains: `export class UserController {`
- Matches: `export class.*Controller`
- Activates: `error-tracking`

#### Best Practices

- Match imports: `import.*[Pp]risma` (case-insensitive with [Pp])
- Escape special regex chars: `\\.findMany\\(` not `.findMany(`
- Patterns use case-insensitive flag
- Test against real file content
- Make patterns specific enough to avoid false matches

---

## Pattern Library

Ready-to-use regex and glob patterns for skill triggers. Copy and customize for your skills.

### Intent Patterns (Regex)

#### Feature/Endpoint Creation
```regex
(add|create|implement|build).*?(feature|endpoint|route|service|controller)
```

#### Component Creation
```regex
(create|add|make|build).*?(component|UI|page|modal|dialog|form)
```

#### Database Work
```regex
(add|create|modify|update).*?(user|table|column|field|schema|migration)
(database|prisma).*?(change|update|query)
```

#### Error Handling
```regex
(fix|handle|catch|debug).*?(error|exception|bug)
(add|implement).*?(try|catch|error.*?handling)
```

#### Explanation Requests
```regex
(how does|how do|explain|what is|describe|tell me about).*?
```

#### Workflow Operations
```regex
(create|add|modify|update).*?(workflow|step|branch|condition)
(debug|troubleshoot|fix).*?workflow
```

#### Testing
```regex
(write|create|add).*?(test|spec|unit.*?test)
```

### File Path Patterns (Glob)

#### Frontend
```glob
frontend/src/**/*.tsx        # All React components
frontend/src/**/*.ts         # All TypeScript files
frontend/src/components/**   # Only components directory
```

#### Backend Services
```glob
form/src/**/*.ts            # Form service
email/src/**/*.ts           # Email service
users/src/**/*.ts           # Users service
projects/src/**/*.ts        # Projects service
```

#### Database
```glob
**/schema.prisma            # Prisma schema (anywhere)
**/migrations/**/*.sql      # Migration files
database/src/**/*.ts        # Database scripts
```

#### Workflows
```glob
form/src/workflow/**/*.ts              # Workflow engine
form/src/workflow-definitions/**/*.json # Workflow definitions
```

#### Test Exclusions
```glob
**/*.test.ts                # TypeScript tests
**/*.test.tsx               # React component tests
**/*.spec.ts                # Spec files
```

### Content Patterns (Regex)

#### Prisma/Database
```regex
import.*[Pp]risma                # Prisma imports
PrismaService                    # PrismaService usage
prisma\.                         # prisma.something
\.findMany\(                     # Prisma query methods
\.create\(
\.update\(
\.delete\(
```

#### Controllers/Routes
```regex
export class.*Controller         # Controller classes
router\.                         # Express router
app\.(get|post|put|delete|patch) # Express app routes
```

#### Error Handling
```regex
try\s*\{                        # Try blocks
catch\s*\(                      # Catch blocks
throw new                        # Throw statements
```

#### React/Components
```regex
export.*React\.FC               # React functional components
export default function.*       # Default function exports
useState|useEffect              # React hooks
```

---

## Testing Your Skills

### Test Commands

#### Test UserPromptSubmit (keyword/intent triggers)

```bash
echo '{"session_id":"test","prompt":"your test prompt here"}' | \
  npx tsx .claude/hooks/skill-activation-prompt.ts
```

Expected: Your skill should appear in the output if keywords or intent patterns match.

#### Test PreToolUse (file path/content triggers)

```bash
cat <<'EOF' | npx tsx .claude/hooks/skill-verification-guard.ts
{"session_id":"test","tool_name":"Edit","tool_input":{"file_path":"/path/to/test/file.ts"}}
EOF
echo "Exit code: $?"
```

Expected:
- Exit code 2 + stderr message if should block
- Exit code 0 + no output if should allow

### Best Practices Summary

#### DO:
✅ Use specific, unambiguous keywords
✅ Test all patterns with real examples
✅ Include common variations
✅ Use non-greedy regex: `.*?`
✅ Escape special characters in content patterns
✅ Add exclusions for test files
✅ Make file path patterns narrow and specific
✅ Validate JSON with `jq`
✅ Test regex patterns on https://regex101.com/

#### DON'T:
❌ Use overly generic keywords ("system", "work")
❌ Make intent patterns too broad (false positives)
❌ Make patterns too specific (false negatives)
❌ Forget to test with regex tester
❌ Use greedy regex: `.*` instead of `.*?`
❌ Match too broadly in file paths
❌ Use trailing commas in JSON
❌ Use single quotes in JSON (must be double quotes)

---

**Related Files:**
- [SKILL.md](SKILL.md) - Main skill guide and quick start
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Debugging skill activation issues
- [INTERNALS.md](INTERNALS.md) - Deep dive into hook mechanisms
