/** Prevents opening the home page mid-scroll (browser restore / leftover hash). */
export function HomeScrollScript() {
  const code = `(function(){try{if("scrollRestoration"in history)history.scrollRestoration="manual";var p=location.pathname;if(!/^\\/(ar|en)\\/?$/.test(p))return;if(sessionStorage.getItem("touri-scroll-to"))return;if(location.hash)history.replaceState(null,"",p+location.search);window.scrollTo(0,0);}catch(e){}})();`;
  return <script dangerouslySetInnerHTML={{ __html: code }} />;
}
