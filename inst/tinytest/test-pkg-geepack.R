source("helpers.R", local = TRUE)
if (ON_CRAN) exit_file("on cran")
requiet("geepack")
requiet("emmeans")
requiet("broom")

# Stata does not replicate coefficients exactly:
# xtset Pig Time
# xtgee Weight i.Cu, family(poisson) link(identity) corr(ar 1)

# geepack::geeglm: marginaleffects vs. emtrends
data(dietox, package = "geepack")
dietox$Cu <- as.factor(dietox$Cu)
mf <- formula(Weight ~ Cu * (Time + I(Time^2) + I(Time^3)))
model <- suppressWarnings(geeglm(mf,
data = dietox, id = Pig,
family = poisson("identity"), corstr = "ar1"))
expect_marginaleffects(model)
# emmeans
mfx <- marginaleffects(model, variables = "Time", newdata = datagrid(Time = 10, Cu = "Cu000"), type = "link")
em <- suppressMessages(emtrends(model, ~Time, var = "Time", at = list(Time = 10, Cu = "Cu000")))
em <- tidy(em)
expect_equivalent(mfx$dydx, em$Time.trend, tolerance = .001)
expect_equivalent(mfx$std.error, em$std.error, tolerance = .01)


# predictions: geepack::geeglm: no validity
data(dietox, package = "geepack")
dietox$Cu <- as.factor(dietox$Cu)
mf <- formula(Weight ~ Cu * (Time + I(Time^2) + I(Time^3)))
model <- suppressWarnings(geeglm(mf, data=dietox, id=Pig, 
                             family=poisson("identity"), corstr="ar1"))
pred1 <- predictions(model)
pred2 <- predictions(model, newdata = head(dietox))
expect_predictions(pred1, n_row = nrow(dietox))
expect_predictions(pred2, n_row = 6)


# TODO: why no support for standard errors?
# marginalmeans: geepack::geeglm: vs. emmeans
data(dietox, package = "geepack")
dietox$Cu <- as.factor(dietox$Cu)
mf <- formula(Weight ~ Cu + Time + I(Time^2) + I(Time^3))
model <- suppressWarnings(geeglm(mf, data=dietox, id=Pig, 
                             family=poisson("identity"), corstr="ar1"))
mm <- marginalmeans(model, variables = "Cu")
em <- emmeans::emmeans(model, ~Cu, type = "response", df = Inf)
em <- data.frame(em)
expect_equal(mm$marginalmean, em$emmean)
expect_equal(mm$conf.low, em$asymp.LCL)
expect_equal(mm$conf.high, em$asymp.UCL)

