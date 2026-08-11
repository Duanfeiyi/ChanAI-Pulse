function  get_skywave_confs(app)
app.sps.day = app.Day.Value;
app.sps.latitude = app.Latitude.Value/180*pi;
app.sps.hour = app.Hour.Value;
app.sps.R12 = app.R12.Value;
app.sps.Bx = app.Bx.Value;
end

