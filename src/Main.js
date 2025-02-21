export function setInnerHTML(element) {
  return function(html) {
    return function() {
      element.innerHTML = html;
    };
  };
} 