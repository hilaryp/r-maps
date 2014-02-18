function showTooltip(evt, label) {
    // Getting rid of any existing tooltips
    hideTooltip();

    var svgNS = "http://www.w3.org/2000/svg",
        target = evt.currentTarget,
        wrappingGroup = document.getElementsByTagName("g")[0];

    // Create a span node to hold the tooltip HTML
    var content = document.createElementNS("http://www.w3.org/1999/xhtml", "span");
    content.innerHTML = label;

    var text = document.createElementNS(svgNS, "foreignObject");
    text.setAttribute("id", "tooltipText");
    // foreignObject nodes must have a width and height
    // explicitly set; they do not auto-size.  Thus, well
    // initially set the width and height to a large value, then
    // measure how much space is actually used by the span node
    // created above.  Then, we set the width and height to
    // exactly those values.
    text.setAttribute("width", "1000");
    text.setAttribute("height", "1000");
    text.appendChild(content);
    wrappingGroup.appendChild(text);
    var r = content.getBoundingClientRect();
    wrappingGroup.removeChild(text);
    var width = r.width, height = r.height;
    if (/Chrome/.test(navigator.userAgent)) {
        // Chrome gives us a zoomed rect; Firefox a natural one.
        width = width / document.documentElement.currentScale;
        height = height / document.documentElement.currentScale;
    }
    text.setAttribute("width", width);
    text.setAttribute("height", height);

    // By rights we should set this, but it makes Chrome barf.
    // text.setAttribute("requiredExtensions",
    //                   "http://www.w3.org/1999/xhtml");

    var rect = document.createElementNS(svgNS, "rect");
    rect.setAttribute("id", "tooltipRect");


    // Add rect and span to the bottom of the document.  This is
    // because SVG has a rendering order.  We want the tooltip to
    // be on top, therefore inserting last.
    wrappingGroup.appendChild(rect);
    wrappingGroup.appendChild(text);

    // Transforming the mouse location to the SVG coordinate system
    // Snippet lifted from:
    // http://tech.groups.yahoo.com/group/svg-developers/message/52701
    var m = target.getScreenCTM();
    var p = document.documentElement.createSVGPoint();
    p.x = evt.clientX;
    p.y = evt.clientY;
    p = p.matrixTransform(m.inverse());

    // Determine position for tooltip based on location of
    // element that mouse is over
    // AND size of text label
    // Currently the tooltip is offset by (3, 3)
    var tooltipx = p.x + 3;
    var tooltiplabx = tooltipx + 5;
    var tooltipy = p.y + 3;
    var tooltiplaby = tooltipy + 5;

    // Position tooltip rect and text
    text.setAttribute("transform",
                      "translate(" + tooltiplabx + ", " +
                      (tooltiplaby + height - 3) + ") " +
                      "scale(1, -1)");

    rect.setAttribute("x", tooltipx);
    rect.setAttribute("y", tooltipy);
    rect.setAttribute("width", width + 10);
    rect.setAttribute("height", height + 5);
    rect.setAttribute("stroke", "black");
    rect.setAttribute("fill", "yellow");
}

function hideTooltip() {
  // Remove tooltip text and rect
  var text = document.getElementById("tooltipText");
  var rect = document.getElementById("tooltipRect");

  if (text !== null && rect !== null) {
    text.parentNode.removeChild(text);
    rect.parentNode.removeChild(rect);
  }
}

function mouseoverHandler(e) {
    showTooltip(e, this.getAttribute("data-tooltip"));
}

function mouseoutHandler () {
    hideTooltip();
}

var points = document.getElementsByClassName("points");
var i;
for (i = 0; i < points.length; i++) {
    points[i].onmouseover = mouseoverHandler;
    points[i].onmouseout = mouseoutHandler;
}
