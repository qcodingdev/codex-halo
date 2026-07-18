import { HaloOverlay } from "./components/HaloOverlay";
import { useStateManager } from "./state/useStateManager";

function App() {
  const { currentState, theme } = useStateManager();

  return (
    <main className="halo-root" aria-hidden="true">
      <HaloOverlay state={currentState} themeId={theme} />
    </main>
  );
}

export default App;
