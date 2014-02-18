library(mapdata)
library(ggplot2)
library(dplyr)
library(stringr)
library(proto)
library(gridSVG)
library(ggmap)
library(grid)
library(RColorBrewer)

u.data <- read.csv("HOUSE.csv")
u.data[50:55,]

conservative.vowels <- c("ᵊuː","ᵓuː","ᶷuː","uː",
                         "ʊ") ## upsilon only in "drought"

singleSummary <- function(vowels, word) {
    s <- sum(vowels %in% conservative.vowels)
    if (s > 1) {
        return (paste0(word, " (x", s, ")"))
    } else if (s == 1) {
        return (word)
    } else {
        return (NA)
    }
}
summaryString <- function(house, how, about, clouds, drought) {
    r <- ""
    x <- singleSummary(house, "House")
    if (!is.na(x)) r <- paste0(r, x, "<br />")

    x <- singleSummary(how, "How")
    if (!is.na(x)) r <- paste0(r, x, "<br />")

    x <- singleSummary(about, "About")
    if (!is.na(x)) r <- paste0(r, x, "<br />")

    x <- singleSummary(clouds, "Clouds")
    if (!is.na(x)) r <- paste0(r, x, "<br />")

    x <- singleSummary(drought, "Drought")
    if (!is.na(x)) r <- paste0(r, x, "<br />")

    ## Strip a trailing <br />
    r <- str_sub(r, end = -7)
    r <- ifelse(r == "", "(none)", r)
    return (r)
}

u.data <- tbl_df(u.data)
u.plot.data <- u.data %.%
    group_by(Town, Latitude, Longitude) %.%
    summarise(NUnLowered =
              sum(House %in% conservative.vowels,
                  How %in% conservative.vowels,
                  About %in% conservative.vowels,
                  Clouds %in% conservative.vowels,
                  Drought %in% conservative.vowels),
              UnLoweredWds = summaryString(
                 House, How, About, Clouds, Drought),
              N = n())
u.plot.data$N <- u.plot.data$N * 5
head(as.data.frame(u.plot.data[20:25,]))

mapdata <- map_data("worldHires", "UK")

geom_tooltip <- function (mapping = NULL, data = NULL, stat = "identity",
                          position = "identity", real.geom = NULL, ...) {
    rg <- real.geom(mapping = mapping, data = data, stat = stat, ## (ref:init)
                    position = position, ...)

    rg$geom <- proto(rg$geom, { ## (ref:proto)
        draw <- function(., data, ...) {
            grobs <- list()
            for (i in 1:nrow(data)) {
                grob <- .super$draw(., data[i,], ...) ## (ref:each)
                grobs[[i]] <- garnishGrob(grob,  ## (ref:garnish)
                                          `data-tooltip`=data[i,]$tooltip)
            }
            ggplot2:::ggname("geom_tooltip", gTree(
                children = do.call("gList", grobs)
                ))
        }
        required_aes <- c("tooltip", .super$required_aes)
    })

    rg ## (ref:return)
}

jscript <- '
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


    // Add rect and span to the bottom of the document.  This is because SVG
    // has a rendering order.  We want the tooltip to be on top, therefore
    // inserting last.
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
'

svgDest <- "u.svg"
gridsvg(svgDest,exportJS="inline",addClasses=TRUE,width=8,height=6)
ggplot(u.plot.data, aes(x = Longitude, y = Latitude)) +
    geom_tooltip(aes(tooltip = paste0(
                         "<b>Words not lowered:</b><br />",
                         UnLoweredWds),
                     color = NUnLowered / N, size = N),
                 real.geom = geom_point) +
    geom_polygon(aes(x = long, y = lat, group = group), data = mapdata,
                 color = "black", fill = NA) +
    coord_map(xlim=c(-5,1), ylim=c(53,56)) +
    theme_nothing(legend = TRUE) +
    theme(plot.title = element_text(size = 16, vjust = 2),
          plot.margin = unit(c(0.5, 0.1, 0.1, 0.1), "in")) +
    ggtitle("/u/-lowering in the North of England") +
    scale_color_gradientn("Percent not lowered",
                          colours=brewer.pal(6, "RdYlGn")) +
    scale_size_area(max_size=4, guide = FALSE)
grid.script(jscript)
dev.off()
