import { useState } from 'react';
import { clearSession, loadSession } from './api';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';

export default function App() {
  const [session, setSession] = useState(() => loadSession());

  if (!session) {
    return <Login onLogin={setSession} />;
  }

  return (
    <Dashboard
      session={session}
      onLogout={() => {
        clearSession();
        setSession(null);
      }}
      onExpired={() => {
        clearSession();
        setSession(null);
      }}
    />
  );
}
