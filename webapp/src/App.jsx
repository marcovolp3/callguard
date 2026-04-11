import { useState } from 'react'
import Search from './pages/Search'
import Report from './pages/Report'
import Feed from './pages/Feed'
import './App.css'

function App() {
  const [page, setPage] = useState('search')

  return (
    <div className="app">
      <header className="header">
        <div className="header-content">
          <div className="logo">
            <span style={{fontSize: 28}}>🛡️</span>
            <h1>CallGuard</h1>
          </div>
          <p className="tagline">Proteggi te stesso dalle chiamate spam</p>
        </div>
      </header>

      <main className="main">
        {page === 'search' && <Search />}
        {page === 'report' && <Report />}
        {page === 'feed' && <Feed />}
      </main>

      <nav className="bottom-nav">
        <button 
          className={`nav-btn ${page === 'search' ? 'active' : ''}`}
          onClick={() => setPage('search')}
        >
          <span className="nav-icon">🔍</span>
          <span>Cerca</span>
        </button>
        <button 
          className={`nav-btn ${page === 'report' ? 'active' : ''}`}
          onClick={() => setPage('report')}
        >
          <span className="nav-icon">⚠️</span>
          <span>Segnala</span>
        </button>
        <button 
          className={`nav-btn ${page === 'feed' ? 'active' : ''}`}
          onClick={() => setPage('feed')}
        >
          <span className="nav-icon">📋</span>
          <span>Feed</span>
        </button>
      </nav>
    </div>
  )
}

export default App
