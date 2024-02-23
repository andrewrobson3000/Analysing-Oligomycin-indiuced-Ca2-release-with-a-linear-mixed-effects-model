# Load necessary libraries
library(tidyverse)
library(readxl)
library(lme4)
library(lmerTest)
library(ggplot2)
library(car)
# Set working directory (adjust to your path)
setwd("C:/Users/HP/Desktop/Calhm2")
# Read data from Excel
data <- read_excel("oligo.xlsx", sheet = "combined")

# Extract control and mutant data
control_data <- data[, 1:7]
mutant_data <- data[, 14:22]

# Create a time vector
time_vector <- 1:nrow(data)

# Attach the time vector to the control and mutant data
control_data$time <- time_vector
mutant_data$time <- time_vector

# Reshape data into long format for control and mutant
control_long <- control_data %>%
  pivot_longer(cols = -time, names_to = "variable", values_to = "value") %>%
  mutate(group = "Control")

mutant_long <- mutant_data %>%
  pivot_longer(cols = -time, names_to = "variable", values_to = "value") %>%
  mutate(group = "Mutant")

# Combine datasets
combined_data <- rbind(control_long, mutant_long)

# Filter data for timepoints from 0 to 130 seconds
filtered_data_full <- combined_data %>% filter(time <= 130)

# Calculate mean and standard error values for control and mutant groups (full range)
summary_data_full <- filtered_data_full %>%
  group_by(group, time) %>%
  summarise(
    mean_value = mean(value),
    se_value = sd(value) / sqrt(n())
  )

# Create a plot with standard error bars (full range)
ggplot(summary_data_full, aes(x = time, y = mean_value, color = group)) +
  geom_line() +
  geom_errorbar(
    aes(ymin = mean_value - se_value, ymax = mean_value + se_value, color = group),
    width = 0.2
  ) +
  labs(
    title = "Mean Fluorescent Intensity with Standard Error Bars (0 to 130 Seconds)",
    x = "Time (seconds)",
    y = "Mean Fluorescent Intensity"
  ) +
  theme_minimal()

# Filter data for timepoints from 45 to 130 seconds
filtered_data <- combined_data %>% filter(time >= 45, time <= 130)

# Calculate mean and standard error values for control and mutant groups (45 to 130 seconds)
summary_data <- filtered_data %>%
  group_by(group, time) %>%
  summarise(
    mean_value = mean(value),
    se_value = sd(value) / sqrt(n())
  )

# Create a plot with standard error bars (45 to 130 seconds)
ggplot(summary_data, aes(x = time, y = mean_value, color = group)) +
  geom_line() +
  geom_errorbar(
    aes(ymin = mean_value - se_value, ymax = mean_value + se_value, color = group),
    width = 0.2
  ) +
  labs(
    title = "Mean Fluorescent Intensity with Standard Error Bars (45 to 130 Seconds)",
    x = "Time (seconds)",
    y = "Mean Fluorescent Intensity"
  ) +
  theme_minimal() +
  coord_cartesian(xlim = c(45, 130))

# Split data into after oligomycin addition (45 seconds onwards)
after_oligo <- filter(filtered_data, time >= 45)

# Linear mixed-effects model
lme_model <- lmer(value ~ time * group + (1 | variable), data = after_oligo)

# Summary of the model
summary(lme_model)

# ANOVA to test the interaction effect of time and group
anova(lme_model)

# Diagnostic plots for residuals
plot(residuals(lme_model))

# Check random effects
ranef(lme_model)

# Model comparison (example)
lme_model_simple <- lmer(value ~ time + group + (1 | variable), data = after_oligo)
anova(lme_model, lme_model_simple)

# Goodness of fit measures
AIC(lme_model)
BIC(lme_model)

# Baseline correction
# Calculate baseline values (at 45 seconds)
baseline_values <- filtered_data %>% 
  filter(time == 45) %>%
  group_by(variable) %>%
  summarise(baseline = mean(value))

# Merge baseline values with the main dataset
data_with_baseline <- left_join(filtered_data, baseline_values, by = "variable")

# Adjust values by subtracting baseline
data_with_baseline$adjusted_value <- data_with_baseline$value - data_with_baseline$baseline

# Update your model with the adjusted values
lme_model_adjusted <- lmer(adjusted_value ~ time * group + (1 | variable), data = data_with_baseline)

# Summary of the adjusted model
summary(lme_model_adjusted)

# ANOVA to test the interaction effect of time and group in the adjusted model
anova(lme_model_adjusted)

# Calculate mean and standard error values for control and mutant groups with adjusted values
summary_data_adjusted <- data_with_baseline %>%
  group_by(group, time) %>%
  summarise(
    mean_adjusted_value = mean(adjusted_value),
    se_adjusted_value = sd(adjusted_value) / sqrt(n())
  )

# Plotting the adjusted data
ggplot(summary_data_adjusted, aes(x = time, y = mean_adjusted_value, color = group)) +
  geom_line() +
  geom_errorbar(
    aes(ymin = mean_adjusted_value - se_adjusted_value, ymax = mean_adjusted_value + se_adjusted_value, color = group),
    width = 0.2
  ) +
  labs(
    title = "Adjusted Mean Fluorescent Intensity with Standard Error Bars (45 to 130 Seconds)",
    x = "Time (seconds)",
    y = "Adjusted Mean Fluorescent Intensity"
  ) +
  theme_minimal() +
  coord_cartesian(xlim = c(45, 130))