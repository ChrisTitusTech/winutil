const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const test = require('node:test');

const workflow = fs.readFileSync(path.join(__dirname, '../workflows/close-discussion-on-pr.yaml'), 'utf8');
const script = workflow.split('        run: |\n')[1]
  .split('        shell: bash')[0]
  .split('\n')
  .map(line => line.slice(10))
  .join('\n');

function run(lookup, close) {
  const mockCurl = `
    curl() {
      local payload='' token='' endpoint=''
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --data) payload="$2"; shift 2 ;;
          -H) [ "$2" = "Authorization: token $GITHUB_TOKEN" ] && token=present; shift 2 ;;
          -X) shift 2 ;;
          http*) endpoint="$1"; shift ;;
          *) shift ;;
        esac
      done
      [ "$token" = present ] && [ "$endpoint" = "$GITHUB_API_URL/graphql" ] || return 1
      printf 'REQUEST:%s\\n' "$payload" >&2
      if [[ "$(jq -r '.query' <<< "$payload")" == mutation* ]]; then
        printf '%s\\n' "$MOCK_CLOSE"
      else
        printf '%s\\n' "$MOCK_LOOKUP"
      fi
    }
  `;
  const result = spawnSync('bash', ['-eo', 'pipefail', '-c', mockCurl + script], {
    encoding: 'utf8',
    env: {
      ...process.env,
      PR_BODY: 'Resolves #123',
      GITHUB_REPOSITORY: 'owner/repo',
      GITHUB_API_URL: 'https://api.github.example',
      GITHUB_TOKEN: 'test-token',
      MOCK_LOOKUP: JSON.stringify(lookup),
      MOCK_CLOSE: JSON.stringify(close)
    }
  });
  assert.equal(result.status, 0, result.stderr);
  return {
    output: result.stdout,
    requests: result.stderr.trim().split('\n')
      .filter(line => line.startsWith('REQUEST:'))
      .map(line => JSON.parse(line.slice('REQUEST:'.length)))
  };
}

test('looks up the discussion number and closes the returned node ID', () => {
  const result = run(
    { data: { repository: { discussion: { id: 'D_node' } } } },
    { data: { closeDiscussion: { discussion: { closed: true } } } }
  );
  assert.equal(result.requests.length, 2);
  assert.match(result.requests[0].query, /discussion\(number: \$number\)/);
  assert.deepEqual(result.requests[0].variables, { owner: 'owner', name: 'repo', number: 123 });
  assert.match(result.requests[1].query, /closeDiscussion\(input: \{discussionId: \$id\}\)/);
  assert.deepEqual(result.requests[1].variables, { id: 'D_node' });
  assert.match(result.output, /Successfully closed discussion #123/);
});

test('does not close when the GraphQL lookup fails', () => {
  const result = run({ errors: [{ message: 'Not found' }] }, {});
  assert.equal(result.requests.length, 1);
  assert.match(result.output, /Warning: Failed to look up discussion #123/);
});

test('reports GraphQL mutation failures instead of claiming success', () => {
  const result = run(
    { data: { repository: { discussion: { id: 'D_node' } } } },
    { errors: [{ message: 'Not authorized' }] }
  );
  assert.equal(result.requests.length, 2);
  assert.match(result.output, /Warning: Failed to close discussion #123/);
  assert.doesNotMatch(result.output, /Successfully closed/);
});
