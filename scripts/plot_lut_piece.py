import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import CubicSpline

# Parameters
max_value = 255
midpoint = max_value // 2  # Halfway point
dip_factor = 0.7  # Factor to lower the midpoint (0 to 1)

# Define key points for the curve
x_points = [0, midpoint // 4, midpoint // 2,  midpoint // 2 + 50, midpoint + 80, 50 + midpoint + midpoint // 2, max_value]
y_points = [0, midpoint // 4, midpoint // 2, midpoint // 2 + 50, 80 + midpoint * dip_factor,50 + midpoint + midpoint // 2 - 20, max_value]

# Create a cubic spline through the points
spline = CubicSpline(x_points, y_points)

# Generate x values and corresponding y values
x = np.linspace(0, max_value, 255)
y = spline(x)

# Plot the curve
plt.figure(figsize=(10, 6))
plt.plot(x, y, label="Gamma Curve", color="blue")
plt.scatter(x_points, y_points, color="red", label="Control Points")
plt.plot(x_points, y_points, '--', color="gray", label="Control Polygon")
plt.title("Gamma Correction")
plt.xlabel("Input Intensity (0-255)")
plt.ylabel("Output Intensity (0-255)")
plt.grid(True)
plt.legend()
plt.xlim(0, max_value)
plt.ylim(0, max_value)
plt.show()
