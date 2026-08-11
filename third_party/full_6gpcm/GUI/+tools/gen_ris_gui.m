function h_RIS = gen_ris_gui(app)
%GEN_RIS_GUI 此处显示有关此函数的摘要
h_RIS = RIS(app.EditField_RISx.Value, app.EditField_RISy.Value, app.EditField_RISdelta_x.Value, app.EditField_RISdelta_y.Value, app.EditField_RISwidth.Value, app.EditField_RISheight.Value); %
h_RIS.ini_position(1) = app.EditField_RISposx.Value;
h_RIS.ini_position(2) = app.EditField_RISposy.Value;
h_RIS.ini_position(3) = app.EditField_RISposz.Value;

h_RIS.normal_global_RIS(1) = app.vectorEditField_6.Value;
h_RIS.normal_global_RIS(2) = app.vectorEditField_7.Value;
h_RIS.normal_global_RIS(3) = app.vectorEditField_8.Value;

h_RIS.vecy_global_RIS(1) = app.vectorEditField_3.Value;
h_RIS.vecy_global_RIS(2) = app.vectorEditField_4.Value;
h_RIS.vecy_global_RIS(3) = app.vectorEditField_5.Value;

h_RIS.vecx_global_RIS(1) = app.vectorEditField_1.Value;
h_RIS.vecx_global_RIS(2) = app.vectorEditField_2.Value;
h_RIS.vecx_global_RIS(3) = app.vectorEditField_3.Value;
end

