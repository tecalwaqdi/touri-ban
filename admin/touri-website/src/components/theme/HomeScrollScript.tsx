/** Home scroll bootstrap: keep valid #section hashes, otherwise start at top. */
export function HomeScrollScript() {
  const code = `(function(){try{if("scrollRestoration"in history)history.scrollRestoration="manual";var p=location.pathname;if(!/^\\/(ar|en)\\/?$/.test(p))return;if(sessionStorage.getItem("touri-scroll-to"))return;var id=(location.hash||"").replace(/^#/,"");var ok=/^(customer|driver|features|how|safety|faq|contact|download)$/.test(id);if(!ok){if(location.hash)history.replaceState(null,"",p+location.search);window.scrollTo(0,0);}}catch(e){}})();`;
  return <script dangerouslySetInnerHTML={{ __html: code }} />;
}
