import React, { useState } from 'react'
import Editor, { OnMount } from '@monaco-editor/react'
import { Runtime } from '../types/editor.types'

interface CodeEditorProps {
  value: string
  onChange: (value: string) => void
  runtime: Runtime
}

export const CodeEditor: React.FC<CodeEditorProps> = ({ value, onChange, runtime }) => {
  const [isFocused, setIsFocused] = useState(false)
  const language = runtime === 'Node.js' ? 'javascript' : 'python'

  const handleEditorDidMount: OnMount = (editor, monaco) => {
    // Track focus state
    editor.onDidFocusEditorText(() => {
      setIsFocused(true)
    })

    editor.onDidBlurEditorText(() => {
      setIsFocused(false)
    })
    // Define custom theme
    monaco.editor.defineTheme('runna-dark', {
      base: 'vs-dark',
      inherit: true,
      rules: [
        { token: 'comment', foreground: '5a7a5a', fontStyle: 'italic' },
        { token: 'keyword', foreground: 'b57ab5' },
        { token: 'string', foreground: 'c88a6a' },
        { token: 'number', foreground: 'a0b898' },
        { token: 'function', foreground: 'c8c088' },
        { token: 'variable', foreground: '88b8c8' },
        { token: 'type', foreground: '48b098' },
        { token: 'operator', foreground: '888888' },
      ],
      colors: {
        'editor.background': '#0a0a0a',
        'editor.foreground': '#b8b8b8',
        'editor.lineHighlightBackground': '#ffffff05',
        'editor.selectionBackground': '#fece6d25',
        'editor.inactiveSelectionBackground': '#fece6d10',
        'editorCursor.foreground': '#fece6d',
        'editorLineNumber.foreground': '#4a4a4a',
        'editorLineNumber.activeForeground': '#fece6d',
        'editor.selectionHighlightBackground': '#ffffff08',
        'editor.wordHighlightBackground': '#ffffff08',
        'editorIndentGuide.background': '#ffffff08',
        'editorIndentGuide.activeBackground': '#ffffff15',
        'editorBracketMatch.background': '#ffffff10',
        'editorBracketMatch.border': '#fece6d60',
        'editorWidget.background': '#0f0f0f',
        'editorWidget.border': '#ffffff10',
        'editorSuggestWidget.background': '#0f0f0f',
        'editorSuggestWidget.border': '#ffffff10',
        'editorSuggestWidget.selectedBackground': '#fece6d20',
        'editorHoverWidget.background': '#0f0f0f',
        'editorHoverWidget.border': '#ffffff10',
        'scrollbarSlider.background': '#ffffff10',
        'scrollbarSlider.hoverBackground': '#ffffff15',
        'scrollbarSlider.activeBackground': '#ffffff20',
      },
    })

    // Set the custom theme
    monaco.editor.setTheme('runna-dark')

    // Enable syntax validation for JavaScript
    if (language === 'javascript') {
      monaco.languages.typescript.javascriptDefaults.setDiagnosticsOptions({
        noSemanticValidation: false,
        noSyntaxValidation: false,
      })

      monaco.languages.typescript.javascriptDefaults.setCompilerOptions({
        target: monaco.languages.typescript.ScriptTarget.ES2020,
        allowNonTsExtensions: true,
        allowJs: true,
        checkJs: false,
      })
    }

    // Add keyboard shortcuts
    editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS, () => {
      // Trigger save (handled by parent component)
      const event = new CustomEvent('editor-save')
      window.dispatchEvent(event)
    })

    // Format on save
    editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyMod.Shift | monaco.KeyCode.KeyF, () => {
      editor.getAction('editor.action.formatDocument')?.run()
    })
  }

  return (
    <div
      className={`h-full rounded-lg overflow-hidden bg-[#0a0a0a] shadow-inner transition-all duration-300 ${
        isFocused
          ? 'border border-primary/50 shadow-lg shadow-primary/20'
          : 'border border-white/10'
      }`}
    >
      <Editor
        height="100%"
        language={language}
        value={value}
        onChange={(value) => onChange(value || '')}
        onMount={handleEditorDidMount}
        theme="runna-dark"
        options={{
          // Appearance
          minimap: { enabled: false },
          fontSize: 14,
          fontFamily: "'JetBrains Mono', 'Fira Code', 'Cascadia Code', 'Consolas', monospace",
          fontLigatures: true,
          lineHeight: 22,
          letterSpacing: 0.5,
          
          // Line numbers
          lineNumbers: 'on',
          lineNumbersMinChars: 3,
          glyphMargin: false,
          folding: true,
          foldingHighlight: true,
          
          // Scrolling
          scrollBeyondLastLine: false,
          smoothScrolling: true,
          mouseWheelZoom: true,
          
          // Layout
          automaticLayout: true,
          padding: { top: 16, bottom: 16 },
          
          // Editing
          tabSize: 2,
          insertSpaces: true,
          formatOnPaste: true,
          formatOnType: true,
          autoClosingBrackets: 'always',
          autoClosingQuotes: 'always',
          autoIndent: 'full',
          
          // Suggestions
          quickSuggestions: {
            other: true,
            comments: false,
            strings: true,
          },
          suggestOnTriggerCharacters: true,
          acceptSuggestionOnCommitCharacter: true,
          acceptSuggestionOnEnter: 'on',
          tabCompletion: 'on',
          wordBasedSuggestions: 'off',
          
          // Behavior
          cursorBlinking: 'smooth',
          cursorSmoothCaretAnimation: 'on',
          renderLineHighlight: 'all',
          renderWhitespace: 'selection',
          bracketPairColorization: {
            enabled: true,
          },
          guides: {
            bracketPairs: true,
            indentation: true,
          },
          
          // Performance
          scrollbar: {
            vertical: 'auto',
            horizontal: 'auto',
            useShadows: true,
            verticalScrollbarSize: 10,
            horizontalScrollbarSize: 10,
          },
        }}
      />
    </div>
  )
}
