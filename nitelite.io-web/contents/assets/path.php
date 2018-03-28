<?php

// This script is dependent on a corresponding database containing
// a simple key-value store. The key is the alias and the value
// is the current valid URL, relative to the root path of the
// website. This database will grow whenever a web url changes
// as all URLs will be permanent, in that old URLs point to the
// new valid location.

define("ROOT_PATH", "https://nitelite.io");
define("DB_FILE", "/var/lib/nitelite/webserver/nitelite.io/database/path.db");
define("ERROR_404", "error-404/index.html");

/**
 * Performs all necessary sanitization procedures for a user-supplied
 * url.
 */
function sanitize_url($path = '') {
  if (empty($path)) {
    return '';
  }
  else {
    // TODO: Url sanitization
    // Trim the leading and trailing slashes.
    $path = trim($path, "/");
    return $path;
  }
}

/**
 * Queries a database for the requested URL. If the request is an alias,
 * return the new location. Otherwise, signal a lookup failure.
 */
function db_lookup($path = '') {
  $new_path = $path;
  if (empty($path)) {
    $new_path = '';
  }
  else {
    // Establish connection.
    try {
      // The db file and this php file are both located in the website's
      // assets/ directory.
      $db = new PDO("sqlite:" . DB_FILE);
      $db->setAttribute(PDO::ATTR_ERRMODE, 
                            PDO::ERRMODE_SILENT);

      // Perform the lookup
      $query = $db->prepare("SELECT * FROM path WHERE key = :path");
      $query->bindValue(":path", $path);
      $query->execute();
      $row = $query->fetch();
      if ($row) {
        $new_path = $row['value'];
      }
      else {
        $new_path = false;
      }

      // Close the connection
      $db = null;
    } catch(PDOException $e) {
      //echo 'ERROR: ' . $e->getMessage();
    }
  }

  return $new_path;
}

// The original request by the user is the path that we are
// going to handle.
$path = $_SERVER['REQUEST_URI'];
$path = sanitize_url($path);

// Perform lookup. If the requested path exists as an alias, display
// the valid URL's content. Otherwise, display the customized 404 page.
$new_path = db_lookup($path);

if ($new_path) {
  header("HTTP/1.1 301 Moved Permanently");
  header("Location: " . ROOT_PATH . "/$new_path/");
}
else {
  include_once("../" . ERROR_404);
}

