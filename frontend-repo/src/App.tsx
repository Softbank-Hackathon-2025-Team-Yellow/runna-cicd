import { BrowserRouter, Routes, Route } from 'react-router-dom'
import LandingPage from './pages/LandingPage'
import FunctionGalleryPage from './pages/FunctionGalleryPage'
import CreateFunctionPage from './pages/CreateFunctionPage'
import FunctionDetailPage from './pages/FunctionDetailPage'
import FunctionLogsPage from './pages/FunctionLogsPage'

function App(): JSX.Element {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/gallery" element={<FunctionGalleryPage />} />
        <Route path="/create" element={<CreateFunctionPage />} />
        <Route path="/functions/:functionId" element={<FunctionDetailPage />} />
        <Route path="/functions/:functionId/logs" element={<FunctionLogsPage />} />
        <Route path="/edit/:functionId" element={<CreateFunctionPage />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
