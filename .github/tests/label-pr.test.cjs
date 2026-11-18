const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const workflow = fs.readFileSync(path.join(__dirname, '../workflows/label-pr.yaml'), 'utf8').replace(/\r\n/g, '\n');
const script = workflow.split('          script: |\n')[1]
  .split('\n')
  .map(line => line.slice(12))
  .join('\n');
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const runWorkflow = new AsyncFunction('github', 'context', script);

async function labelChanges(title, labels, files = [{ filename: 'functions/example.ps1' }], eventLabels = []) {
  const calls = [];
  const github = {
    paginate: async () => files,
    rest: {
      pulls: {
        get: async () => ({ data: { number: 42, title, labels: labels.map(name => ({ name })) } }),
        listFiles: () => {}
      },
      issues: {
        addLabels: async ({ labels: added }) => calls.push(['add', ...added]),
        removeLabel: async ({ name }) => calls.push(['remove', name])
      }
    }
  };
  const context = {
    repo: { owner: 'owner', repo: 'repo' },
    payload: { pull_request: { number: 42, title: 'feat: stale event', labels: eventLabels.map(name => ({ name })) } }
  };
  await runWorkflow(github, context);
  return calls;
}

test('retitling adds the current type without removing existing labels', async () => {
  assert.deepEqual(await labelChanges('Fix(ui): corrected', ['new feature', 'documentation', 'custom']), [
    ['add', 'bug']
  ]);
});

test('an unrecognized title preserves all existing labels', async () => {
  assert.deepEqual(await labelChanges('Updated description', ['bug', 'documentation', 'custom']), []);
});

test('an already matching type label is retained', async () => {
  assert.deepEqual(await labelChanges('docs: update', ['documentation', 'custom']), []);
});

test('docs-only reconciliation uses current labels and files without changing manual exclusions', async () => {
  const code = [{ filename: 'functions/example.ps1' }];
  const docs = [{ filename: 'docs/example.mdx' }];
  assert.deepEqual(await labelChanges('Update', ['skip-changelog'], code), []);
  assert.deepEqual(await labelChanges('Update', [], docs, ['docs-only']), [['add', 'docs-only']]);
  assert.deepEqual(await labelChanges('Update', [], code, ['docs-only']), []);
  assert.deepEqual(await labelChanges('Update', ['docs-only', 'skip-changelog'], docs), []);
  assert.deepEqual(await labelChanges('Update', ['docs-only', 'skip-changelog'], code), [['remove', 'docs-only']]);
  assert.deepEqual(await labelChanges('Update', ['skip-changelog'], docs), [['add', 'docs-only']]);
});

test('workflow, tooling and mixed changes remain in release notes', async () => {
  for (const filename of ['.github/workflows/pre-release.yaml', '.github/release-drafter.yml',
    'tools/autounattend.xml', 'tools/autounattend.xml.backup', 'pester/example.Tests.ps1', 'Compile.ps1']) {
    assert.deepEqual(await labelChanges('Update', [], [{ filename }]), [], filename);
    assert.deepEqual(await labelChanges('Update', ['docs-only'], [{ filename }, { filename: 'docs/example.mdx' }]),
      [['remove', 'docs-only']], filename);
  }
});

test('renames check both the old and new path', async () => {
  for (const file of [
    { filename: 'docs/old.xml', previous_filename: 'tools/autounattend.xml' },
    { filename: 'tools/new.xml', previous_filename: 'docs/old.xml' }
  ]) {
    assert.deepEqual(await labelChanges('Update', [], [file]), []);
    assert.deepEqual(await labelChanges('Update', ['docs-only'], [file]), [['remove', 'docs-only']]);
  }
  assert.deepEqual(await labelChanges('Update', [], [
    { filename: 'docs/new.mdx', previous_filename: 'docs/old.mdx' },
    { filename: 'README.md' }
  ]), [['add', 'docs-only']]);
});

test('an empty file list is not classified as docs-only', async () => {
  assert.deepEqual(await labelChanges('Update', [], []), []);
});

test('release notes exclude both automatic docs-only and manual skip-changelog labels', () => {
  const config = fs.readFileSync(path.join(__dirname, '../release-drafter.yml'), 'utf8');
  const exclusions = config.split('exclude-labels:')[1].split(/\n\S/)[0];
  assert.match(exclusions, /^\s+- 'docs-only'\s*$/m);
  assert.match(exclusions, /^\s+- 'skip-changelog'\s*$/m);
});
