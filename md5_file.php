#!/usr/bin/php
<?php
/***************************************************************
* Calculate MD5 hash of file (first and only argument)
*
* 27dec13 EB    First version
***************************************************************/
array_shift( $argv );
echo md5_file( array_shift( $argv ) );
?>
