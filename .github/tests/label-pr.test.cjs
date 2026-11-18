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

test('retitling removes obsolete mapped labels before adding the current label', async () => {
  assert.deepEqual(await labelChanges('Fix(ui): corrected', ['new feature', 'documentation', 'custom']), [
    ['remove', 'new feature'],
    ['remove', 'documentation'],
    ['add', 'bug']
  ]);
});

test('an unrecognized title removes mapped labels but preserves unrelated labels', async () => {
  assert.deepEqual(await labelChanges('Updated description', ['bug', 'custom']), [['remove', 'bug']]);
});

test('an already matching type label is retained', async () => {
  assert.deepEqual(await labelChanges('docs: update', ['documentation', 'custom']), []);
});

test('skip-changelog reconciliation uses current labels and current files', async () => {
  const code = [{ filename: 'functions/example.ps1' }];
  const docs = [{ filename: 'docs/example.mdx' }];
  assert.deepEqual(await labelChanges('Update', ['skip-changelog'], code), [['remove', 'skip-changelog']]);
  assert.deepEqual(await labelChanges('Update', [], docs, ['skip-changelog']), [['add', 'skip-changelog']]);
  assert.deepEqual(await labelChanges('Update', [], code, ['skip-changelog']), []);
  assert.deepEqual(await labelChanges('Update', ['skip-changelog'], docs), []);
});

test('the embedded unattended XML is classified as a code change', async () => {
  const files = [{ filename: 'tools/autounattend.xml' }];
  assert.deepEqual(await labelChanges('Update', [], files), []);
  assert.deepEqual(await labelChanges('Update', ['skip-changelog'], files), [['remove', 'skip-changelog']]);
  assert.deepEqual(
    await labelChanges('Update', ['skip-changelog'], [{ filename: 'docs/old.xml', previous_filename: 'tools/autounattend.xml' }]),
    [['remove', 'skip-changelog']]
  );
  assert.deepEqual(
    await labelChanges('Update', [], [{ filename: 'tools/autounattend.xml.backup' }]),
    [['add', 'skip-changelog']]
  );
});
