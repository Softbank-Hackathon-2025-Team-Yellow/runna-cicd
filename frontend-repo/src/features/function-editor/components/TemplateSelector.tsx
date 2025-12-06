import React from 'react'
import { FileCode } from 'lucide-react'

interface Template {
  id: string
  name: string
  description: string
  runtime: 'Node.js' | 'Python'
  code: string
}

const TEMPLATES: Template[] = [
  {
    id: 'nodejs-hello',
    name: 'Hello World (Node.js)',
    description: 'Simple HTTP response',
    runtime: 'Node.js',
    code: `async function handler(event) {
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Hello World!',
      timestamp: new Date().toISOString()
    })
  };
}

module.exports = { handler };`
  },
  {
    id: 'nodejs-api',
    name: 'REST API (Node.js)',
    description: 'RESTful API endpoint',
    runtime: 'Node.js',
    code: `async function handler(event) {
  const { httpMethod, body } = event;
  
  switch (httpMethod) {
    case 'GET':
      return {
        statusCode: 200,
        body: JSON.stringify({ data: [] })
      };
    case 'POST':
      const data = JSON.parse(body);
      return {
        statusCode: 201,
        body: JSON.stringify({ created: data })
      };
    default:
      return {
        statusCode: 405,
        body: JSON.stringify({ error: 'Method not allowed' })
      };
  }
}

module.exports = { handler };`
  },
  {
    id: 'python-hello',
    name: 'Hello World (Python)',
    description: 'Simple HTTP response',
    runtime: 'Python',
    code: `def handler(event, context):
    return {
        'statusCode': 200,
        'body': {
            'message': 'Hello World!',
            'timestamp': context.get('timestamp')
        }
    }`
  },
  {
    id: 'python-data',
    name: 'Data Processing (Python)',
    description: 'Process and transform data',
    runtime: 'Python',
    code: `def handler(event, context):
    data = event.get('data', [])
    
    # Process data
    processed = [item * 2 for item in data]
    
    return {
        'statusCode': 200,
        'body': {
            'original': data,
            'processed': processed,
            'count': len(processed)
        }
    }`
  }
]

interface TemplateSelectorProps {
  onSelect: (template: Template) => void
  onClose: () => void
}

export const TemplateSelector: React.FC<TemplateSelectorProps> = ({ onSelect, onClose }) => {
  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in">
      <div className="bg-background-dark border border-white/10 rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[80vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <h2 className="font-pixel text-base text-[#fece6d]">Choose a Template</h2>
          <button
            onClick={onClose}
            className="text-white/60 hover:text-white transition-colors"
          >
            ✕
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {TEMPLATES.map((template) => (
            <button
              key={template.id}
              onClick={() => {
                onSelect(template)
                onClose()
              }}
              className="flex flex-col gap-3 p-4 bg-white/[.03] border border-white/10 rounded-lg hover:border-primary/50 hover:bg-white/5 transition-all duration-300 text-left"
            >
              <div className="flex items-start justify-between">
                <FileCode className={`w-5 h-5 ${template.runtime === 'Node.js' ? 'text-green-400' : 'text-blue-400'}`} />
                <span className={`text-xs px-2 py-0.5 rounded ${
                  template.runtime === 'Node.js' 
                    ? 'bg-green-400/10 text-green-400' 
                    : 'bg-blue-400/10 text-blue-400'
                }`}>
                  {template.runtime}
                </span>
              </div>
              <div>
                <h3 className="text-sm font-normal text-white mb-1">{template.name}</h3>
                <p className="text-xs text-white/60">{template.description}</p>
              </div>
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}

export { TEMPLATES }
export type { Template }
