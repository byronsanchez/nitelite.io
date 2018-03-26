<?php

/**
 * comments.php
 *
 * Requires the YAML PECL Extension.
 */

define("DB_FILE", "/var/lib/nitelite/webserver/nitelite.io/database/comments.db");
define("TBL_NAME", "comments");
define("COL_NAME", "message");
// The date stored in YAML format
define("DATE_YAML", "Y-m-d H:i:s");
// The date that the user sees during previews
define("DATE_PREVIEW", "F j, Y g:i A");

/**
 * Validate an input string.
 *
 * @param string $text_string
 * @return integer
 */
function validate_comment(&$text_string = "", &$error_log) {

  // If there are any errors, log them all and return false.
  if (empty($text_string)) {
    $error_log['comment'] = "Please enter something in the comment area.";

    return 0;
  }

  return 1;
}

/**
 * Validate an input string.
 *
 * @param string $text_string
 * @return integer
 */
function validate_name(&$text_string = "", &$error_log) {

  // Names are optional
  return 1;
}

 /**
 * Validate an email address against a @ and . pattern.
 *
 * @param string $email_address
 * @param array $error_log
 * @return boolean
 */
function validate_email(&$email_address, &$error_log) {

  // If there are any errors, log them all and return false.

  // Emails are optional
  if (!empty($email_address)) {
    // Email tags should always be valid as well (example+tag@example.com).
    //$result = preg_match("/.+@.+\..+/i", $email_address);
    $result = filter_var($email_address, FILTER_VALIDATE_EMAIL);

    if (!$result) {
      $error_log['email'] = "Please enter a valid email address";

      return 0;
    }
  }

  // If there were no errors, return true.
  return 1;
}

/**
 * Validate an input string.
 *
 * @param string $text_string
 * @return integer
 */
function validate_link(&$text_string = "", &$error_log) {

  // Links are optional, so don't return false for being empty.
  if (!empty($text_string)) {

  	// Ensure that the link begins with the |http://| portion
  	$text_string = ( strcmp("http://", substr($text_string, 0, 7)) == 0 ? $text_string : "http://" . $text_string );


    // Validate the URL against RFC-2396 standards AFTER providing the resource identifier.
    $result = filter_var($text_string, FILTER_VALIDATE_URL, FILTER_FLAG_HOST_REQUIRED);

    // If there are any errors, log them all and return false.
    if (!$result) {
      $error_log['link'] = "Please enter a valid link";

      return 0;
    }
  }

  // If there were no errors, return true.
  return 1;
}

/**
 * Sanitizes an input string.
 *
 * @param string $text_string
 */
function sanitize_data(&$text_string = "") {
  $text_string = htmlspecialchars($text_string);
}

/**
 * Builds the string to be inserted into the database
 */
function build_form_string($data) {
  $yaml_string = yaml_emit($data);
  return $yaml_string;
}

/**
 * Creates the SQLite database if it does not yet exist.
 *
 * NOTE: This is a fallback in case, for whatever reason, one does not yet
 * exist. The database is also being created by the deployment process. This
 * should be kept in mind in case there are ever any future changes to the
 * database or deployment process.
 */
function db_create() {
  $result = false;

  // Establish connection
  try {
    $db = new PDO("sqlite:" . DB_FILE);
    $db->setAttribute(PDO::ATTR_ERRMODE,
                        PDO::ERRMODE_SILENT);

    $sql = "CREATE TABLE IF NOT EXISTS " . TBL_NAME . "(_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL," . COL_NAME . " TEXT, isPublished INTEGER DEFAULT 0)";
    $db->exec($sql);

    // Close the connection
    $db = null;
  } catch (PDOException $e) {
    //echo 'ERROR ' . $e->getMessage();
  }

  return $result;
}

/**
 * Performs a SQLite insertion operation
 *
 * @param array $data
 */
function db_insert($value) {
  $result = false;

  // Establish connection
  try {
    $db = new PDO("sqlite:" . DB_FILE);
    $db->setAttribute(PDO::ATTR_ERRMODE,
                        PDO::ERRMODE_SILENT);

    // Perform the insertion
    $query = $db->prepare("INSERT INTO " . TBL_NAME . "(" . COL_NAME . ") VALUES (:value)");
    $query->bindValue(":value", $value);
    $result = $query->execute();

    // Close the connection
    $db = null;

  } catch (PDOException $e) {
    // echo 'ERROR: ' . $e->getMessage();
  }

  return $result;
}

/**
 * Generates a unique id for the comment.
 */
function generate_unique_id(&$data) {
  // NOTE: $cstrong will contain a boolean which determines whether or not the
  // algorithm used was crypto-strong. In this case, it doesn't matter and can
  // even be omitted.
  $bytes = openssl_random_pseudo_bytes(4, $cstrong);
  $hex   = bin2hex($bytes);
  $data['id'] = $hex;
}

/*
 * The main program.
 */

// Initialize an error log to output any failed validation.
$error_log = array();

/**
 * For client-side validation responses for complex validation.
 * Called via AJAX.
 */

// Validate the email and return a JSON-encoded response.
if (array_key_exists('invoke', $_POST)) {

  if ($_POST["invoke"] == "validate_email") {

    $result = validate_email($_POST["email"], $error_log);

    // Display an error message by passing the JSON-encoded error log.
    $json_array = $error_log;
    $json_array["validate_result"] = $result;

    echo json_encode( $json_array );
  }

  // Validate the link and return a JSON-encoded response.
  else if ($_POST["invoke"] == "validate_link") {

    $result = validate_link($_POST["link"], $error_log);

    // Display an error message by passing the JSON-encoded error log.
    $json_array = $error_log;
    $json_array["validate_result"] = $result;

    echo json_encode( $json_array );
  }

}



/**
 * Server-side validation invoked upon final form submission.
 */

// Upon post submission of a form, run a full-fledged server-side validation before submitting the data. Failures return a JSON object with the error_log contents.
// NOTE: post is being used for contact messages AND comments.
else if ($_POST["submit"] == "post" || $_POST["submit"] == "preview") {

  // Make a copy of all $_POST data.
  $data = $_POST;
  // Add the date to the data.
  $data['date'] = date(DATE_YAML);

  /**
   * Validation checks.
   */

  // Validate the comment input.
  $isValidComment = validate_comment($data['comment'], $error_log);
  // Validate the name input.
  $isValidName = validate_name($data['name'], $error_log);
  // Validate the email input.
  $isValidEmail = validate_email($data['email'], $error_log);
  // Validate the link input
  $isValidLink = validate_link($data['link'], $error_log);

  /**
   * Sanitization.
   */

  $keys = array_keys($data);
  $size = count($data);
  for ($i = 0; $i < $size; $i++) {
    $key = $keys[$i];
    sanitize_data($data[$key]);
  }

  // If all fields are valid...
  if ($isValidComment && $isValidName && $isValidEmail && $isValidLink) {

    /**
     * Database storage. (COMMENT OR CONTACT)
     */

    if ($_POST["submit"] == "post" || $_POST["submit"] == "contact") {

      // Generate a unique id for the message
      generate_unique_id($data);

      // 2018-03-12 Update:
      //
      // Commenting is now being handled by disqus. Contact messages are sent
      // through email. YAML is still used to format the data nicely in email,
      // but sqlite3 is no longer needed server side. Keeping the code following
      // DNA pattern.

      // Create the table IF IT DOES NOT ALREADY EXIST
      //      db_create();
      $value = build_form_string($data);
      //      $db_result = db_insert($value);

      $to = 'byron@nitelite.io';
      $from = $data['email'];
      $subject ='[niteLite.io]: ' . $data['id'] . ' - ' . $data['name'] . ' <' . $data['email'] . '>';
      $name = $data['name'];

      $message = $data['comment'] . "\r\n";

      $message .= "\r\n";
      $message .= "---\r\n";
      // $message .= "\r\n";
      $message .= "Name: " . $data['name'] . "\r\n";
      $message .= "Email: " . $data['email'] . "\r\n";
      $message .= "Link: " . $data['link'] . "\r\n";
      $message .= "Date: " . $data['date'] . "\r\n";
      $message .= "ID: " . $data['id'] . "\r\n";

      $headers = "MIME-Version: 1.0" . "\r\n";
      $headers .= "Content-type:text/plain;charset=UTF-8" . "\r\n";
      $headers .= "To: {$to}\r\n";
      $headers .= "From: {$name} <{$from}>\r\n";
      $headers .= "Reply-To: <{$from}>\r\n";
      $headers .= "Subject: {$subject}\r\n";
      $headers .= "X-Mailer: PHP/".phpversion()."\r\n";

      $mail_result = mail($to, $subject, $message, $headers);

      if ( $mail_result ) {
        // Display a success message by passing a JSON-encoded success signal.
        $json_array = array();
        $json_array["submit_result"] = 1;

        echo json_encode( $json_array );
      }
      else {
        // Display a generic error message.
        $json_array = array();
        $json_array["submit_result"] = 0;
        $json_array["error"] = "There was a problem processing the submission. Please try again.";

        echo json_encode( $json_array );
      }
    }

    /**
     * Preview formatting.
     */

    if ($_POST["submit"] == "preview") {

      /**
       * Redcarpet.
       */

      // Build the descriptor spec for running an external process.
      $descriptorspec = array(
       0 => array("pipe", "r"),  // stdin is a pipe that the child will read from
       1 => array("pipe", "w"),  // stdout is a pipe that the child will write to
       //2 => array("file", "./error-output.txt", "a") // stderr is a file to write to
       2 => array("pipe", "w")   // stderr is a pipe that the child will write to
      );

      // Start the process.
      $process = proc_open('node ./bs-forms.js', $descriptorspec, $pipes);
      $return_value = -1;
      if (is_resource($process)) {
        // $pipes now looks like this:
        // 0 => writeable handle connected to child stdin
        // 1 => readable handle connected to child stdout
        // Any error output will be appended to /tmp/error-output.txt

        // Write the comment to STDIN.
        fwrite($pipes[0], $data['comment']);
        // Close the STDIN pipe.
        fclose($pipes[0]);

        // Get STDOUT data and store it locally.
        $data['comment'] = stream_get_contents($pipes[1]);
        // Close the STDOUT pipe.
        fclose($pipes[1]);

        // Get STDERR data and store it locally.
        $pipe_error = stream_get_contents($pipes[2]);
        // Close the STDERR pipe.
        fclose($pipes[2]);

        // It is important that you close any pipes before calling
        // proc_close in order to avoid a deadlock

        // This is the exit RV. NOT RELIABLE (the RV will be -1 if the application
        // exited on its own before this call).
        $return_value = proc_close($process);

        // Update the return value based on whether the application itself
        // outputed any errors to STDERR.
        if (!empty($pipe_error)) {
          $return_value = -1;
        }
        else {
          $return_value = 0;
        }
      }

      // If the ruby application outputted no errors to STDERR
      if ($return_value == 0) {

        // Format the data for preview.

        // Add the date to the response object.
        $data['date'] = date(DATE_PREVIEW);

        // Create the JSON object.
        $json_array = $data;
        $json_array["submit_result"] = 1;

        echo json_encode( $json_array );
      }
      // Second redcarpet fail - Else return a JSON object with a failure signal.
      else {
        // Log a preview error message.
        $error_log['redcarpet'] = "There was a problem loading the preview.";

        // Display an error message by passing the JSON-encoded error log.
        $json_array = $error_log;
        $json_array["submit_result"] = 0;

        echo json_encode( $json_array );
      }

    }

  }
  // First validation fail - Else return a JSON object with a failure signal.
  else {
    // Display an error message by passing the JSON-encoded error log.
    $json_array = $error_log;
    $json_array["submit_result"] = 0;

    echo json_encode( $json_array );
  }
}
else {
  $error_log['oops'] = "There was a problem processing the submission. Please try again.";
  // Display an error message by passing the JSON-encoded error log.
  $json_array = $error_log;
  $json_array["submit_result"] = 0;

  echo json_encode( $json_array );
}
