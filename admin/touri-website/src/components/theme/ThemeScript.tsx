export function ThemeScript() {
  const code =
    "(function(){try{var s=localStorage.getItem('touri-theme');var d=s?s==='dark':window.matchMedia('(prefers-color-scheme: dark)').matches;document.documentElement.classList.toggle('dark',d);}catch(e){}})();";
  return <script dangerouslySetInnerHTML={{ __html: code }} />;
}
