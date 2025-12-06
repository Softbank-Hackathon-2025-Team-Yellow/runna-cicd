export const DEFAULT_NODEJS_CODE = `// Node.js Function
async function handler(event) {
  // Your code here
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Hello from Node.js!',
      input: event
    })
  };
}

module.exports = { handler };`

export const DEFAULT_PYTHON_CODE = `# Python Function
def handler(event, context):
    # Your code here
    return {
        'statusCode': 200,
        'body': {
            'message': 'Hello from Python!',
            'input': event
        }
    }`

export const DEFAULT_TEST_REQUEST = `{
  "name": "test",
  "value": 123
}`
