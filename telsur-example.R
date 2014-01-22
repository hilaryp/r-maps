# telsur-example.R by Hilary Prichard, 13 Jan. 2014
# This file walks you through the code to create a basic ANAE-style map. 

# If you haven't already installed "maps", do so now:
install.packages("maps")

# First load the packages you will need:
library(maps)

# Read the sample telsur data csv into an R dataframe 
telsur <- read.csv("telsur-example.csv") 

# Have a look at the data, does everything look fine? 
summary(telsur)

# Add a new column, color-coding the o_oh variable
# using 'with' here allows you to reference the column name directly 
telsur$colors <- with(telsur, ifelse(o_oh == 0, "forestgreen", 
                      ifelse(o_oh > 0 & o_oh < 20, "orange", 
                      ifelse(o_oh > 19, "blue", "grey"))))
												  
# Now if you look at the first few rows of telsur, you'll see the new column
head(telsur)

# Create a blank map of the U.S.A. with ANAE-style colors
map("state",             # specifies which map to plot
    col = "cornsilk",    # color used to fill the states
    bg = "lightcyan1",   # color used to fill background
    fill = TRUE,         # fill is turned on
    mar = rep(0,4))      # plot margins, in this case none

# plot the o_oh data on top of this map
with(telsur, points(Longitude, Latitude,    # x axis, y axis
                    col = colors,           # point color comes from the column
                    pch = 19,               # point shape = circle
                    cex = .8))              # point size = 0.8

# Note that this is only one approach to color-coding your data, and may not
# be suitable for all data structures. Another simple alternative is to subset 
# your data into multiple data frames and use one points() call for each
# subset, specifying a different color for each. Do whatever makes sense for
# you and your data!

# add a legend to the map
legend("bottomright",                               # position on the plot
       legend = c("merged", "/o/", "/oh/"),         # items in the legend
       pch = 19,                                    # point shape
       cex = .9,                                    # point size
       col = c("blue", "orange", "forestgreen"),    # point color
       title = "Perception of /o/~/oh/",            # legend title
       bg = "white")                                # legend background color
			  
# This looks pretty good! Ultimately you'll want to save your maps; 
# I recommend saving as a pdf, using cairo_pdf(). For journal submission, 
# you may be asked for higher-quality images, in which case use svg(). 
# Here's the full code for saving this map as a pdf:

cairo_pdf("telsur-example.pdf", width = 6.5, height = 4, 
          pointsize = 12, family = "Times")
map("state", col = "cornsilk", bg = "lightcyan1", fill = TRUE, mar = rep(0,4))
with(telsur, points(Longitude, Latitude, col = colors, pch = 19, cex = .8))
legend("bottomright", legend = c("merged", "/o/", "/oh/"), pch = 19, 
       cex = .9, col = c("blue", "orange", "forestgreen"), 
       title = "Perception of /o/~/oh/", bg = "white")
dev.off()

# Note that within cairo_pdf() you can specify map size, font size, and 
# font family. Always follow your map code with dev.off() - this tells R you're
# done adding things to the plot, it's time to create the file. 

# Congrats, now you have your first map! 
# (The pdf should be in the same folder as this code.)


