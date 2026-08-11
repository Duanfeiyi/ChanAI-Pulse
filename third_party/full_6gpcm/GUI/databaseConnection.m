function conn = databaseConnection()
    javaclasspath('mysql-connector-j-9.1.0.jar'); %JAR文件的路径
    dbname = 'seu-pml-6gpcs'; % 
    username = 'awitec_pml'; % 用户名
    password = 'awipmltec1234##'; % 密码
    driver = 'com.mysql.cj.jdbc.Driver';
    dburl = ['jdbc:mysql://bj-cynosdbmysql-grp-rfw36yey.sql.tencentcdb.com:22180/', dbname, '?useSSL=true&requireSSL=true&verifyServerCertificate=true&trustCertificateKeyStoreUrl=file:6gpcs.tmp'...
, '&trustCertificateKeyStorePassword=tencentdb']; % 服务器地址和端口
    conn = database('', username, password, driver, dburl);
end