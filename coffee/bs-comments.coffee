# On document load
$(document).ready( () ->

  "use strict"

  # Define "constant-like" variables.
  MODE_EDIT = 0
  MODE_PREVIEW = 1
  MODE_SUBMIT = 2

  # All possible forms on the site
  $commentForm = $("#comment-form")
  $contactForm = $("#contact-form")

  # Custom prompt messages.
  $sectionNoticeErrorString

  # The selector that will contain the single form to handle.
  $formComment

  # Define the directory for the ajax file.
  $ajax_file = "/assets/bs-forms.php"

  # Comment section headers.
  $headerPostComment = $("#header-post-comment")
  #$headerVerifyComment = $("#header-verify-comment")
  $headerPreviewComment = $("#header-preview-comment")

  # Comment section references.
  $sectionNoticeSuccess = $("#comments-open-response-success")
  $sectionNoticeError = $("#comments-open-response-error")
  $sectionPreview = $("#comment-preview")
  $sectionPreviewConfirmation = $("#comment-preview-confirmation")
  #$sectionCaptcha = $("#comment-captcha")
  $sectionForm = $("#primary-comment-form")

  # Form Fields 
  $fieldComment = $("#comment-text")
  $fieldName = $("#comment-author")
  $fieldEmail = $("#comment-email")
  $fieldLink = $("#comment-url")
  $buttonPost = $("#comment-post-button")
  $buttonPreview = $("#comment-preview-button")
  # Variable identifying which button made the POST request.
  $submit = ""

  # Preview Form Fields.
  $formPreview = $("#comment-preview-form")
  $buttonConfirm = $("#comment-confirm-post")
  $buttonEdit = $("#comment-edit")
  # Variable identifying which button made the POST request.
  $submitPreview = ""

  # UI Elements
  $spinner = $("#commentEntryFormSpinner")
  $spinnerPreview = $("#previewFormSpinner")

  # Insertion references
  $sectionPreviewContent = $("#comment-preview-content")
  $sectionPreviewAuthor = $("#comment-preview-author")
  $sectionPreviewDatetime = $("#comment-preview-datetime")

  # Validation section references.
  $nameInfo = $("#comment-author-error")
  $emailInfo = $("#comment-email-error")
  $linkInfo = $("#comment-url-error")

  # Define validation check variables.
  # Required defaults to false optional defaults to true.
  $isCommentValid = false
  $isNameValid = false
  $isEmailValid = false
  $isLinkValid = true

  # The AJAX request variables.
  $request_validate_email = 0
  $request_validate_link = 0
  $request_submit = 0
  $request_preview = 0

  ###
  Spinner configuration.
  ###

  # Configure the spinner object
  opts = {
    lines: 7,                 # The number of lines to draw
    length: 0,                # The length of each line
    width: 6,                 # The line thickness
    radius: 7,                # The radius of the inner circle
    corners: 1,               # Corner roundness (0..1)
    rotate: 54,               # The rotation offset
    color: '#000',            # #rgb or #rrggbb
    direction: 1,             # 1: clockwise, -1: counterclockwise
    speed: 1.6,               # Rounds per second
    trail: 50,                # Afterglow percentage
    opacity: 1 / 4,           # Opacity of the lines
    fps: 20,                  # Frames per second when using setTimeout()
    shadow: false,            # Whether to render a shadow
    hwaccel: false,           # Whether to use hardware acceleration
    className: 'spinner',     # The CSS class to assign to the spinner
    zIndex: 2e9,              # The z-index (defaults to 2000000000)
    top: '0',                 # Top position relative to parent in px
    left: '0',                # Left position relative to parent in px
    position: 'relative'      # element position
  }

  # Update the parent div dimensions based on the options.
  $spinner.width((opts.width * 2) + (opts.radius * 2))
  $spinner.height((opts.width * 2) + (opts.radius * 2))
  $spinnerPreview.width((opts.width * 2) + (opts.radius * 2))
  $spinnerPreview.height((opts.width * 2) + (opts.radius * 2))
  # Create the spinners
  $spinner.spin(opts)
  $spinnerPreview.spin(opts)

  ###
  Common Functions.
  ###

  ###
  Sets the form state based on the given id.
  ###
  setCommentState = (MODE_ID) ->

    switch (MODE_ID)

      when MODE_EDIT

        # Hide the preview section header.
        $headerPreviewComment.addClass("hiddenBox")
        # Hide the preview section.
        $sectionPreview.addClass("hiddenBox")
        # Hide the preview section form.
        $sectionPreviewConfirmation.addClass("hiddenBox")
        # Show the edit section header.
        $headerPostComment.removeClass("hiddenBox")
        # Show the comment section.
        $sectionForm.removeClass("hiddenBox")
        # Hide the notices.
        $sectionNoticeSuccess.addClass("hiddenBox")
        $sectionNoticeError.addClass("hiddenBox")

      when MODE_PREVIEW

        # Show the preview section header.
        $headerPreviewComment.removeClass("hiddenBox")
        # Show the preview section.
        $sectionPreview.removeClass("hiddenBox")
        # Show the preview section form.
        $sectionPreviewConfirmation.removeClass("hiddenBox")
        # Hide the edit section header.
        $headerPostComment.addClass("hiddenBox")
        # Hide the comment section.
        $sectionForm.addClass("hiddenBox")
        # Hide the notices.
        $sectionNoticeSuccess.addClass("hiddenBox")
        $sectionNoticeError.addClass("hiddenBox")

      when MODE_SUBMIT

        # Hide the preview section header.
        $headerPreviewComment.addClass("hiddenBox")
        # Hide the preview section.
        $sectionPreview.addClass("hiddenBox")
        # Hide the preview section form.
        $sectionPreviewConfirmation.addClass("hiddenBox")
        # Hide the edit section header.
        $headerPostComment.removeClass("hiddenBox")
        # Hide the comment section.
        $sectionForm.addClass("hiddenBox")
        # Hide the notices.
        $sectionNoticeSuccess.addClass("hiddenBox")
        $sectionNoticeError.addClass("hiddenBox")

  ###
  AJAX functions.
  ###

  ###
  Callback function invoked when an AJAX request has been completed via the post/submit button.
  ###
  submit_post_request = (isValidSubmit, optionalResponse) ->
    # Handle output based on response.
    if (isValidSubmit)
      # Only on successful submit, get rid of everything.
      setCommentState(MODE_SUBMIT)

      # Show the actual comment success section.
      $sectionNoticeSuccess.removeClass("hiddenBox")
      $sectionNoticeError.addClass("hiddenBox")

      # Clear all form fields.
      $formComment.find("input[type=text]").add("textarea").val("")
      # Disable the buttons
      $buttonPost.attr("disabled", "disabled")
      $buttonPreview.attr("disabled", "disabled")
      $isCommentValid = false
    else
      # If the JSON object is set (there was a response from the server).
      # This means server-side validation has failed.
      if (typeof optionalResponse == "undefined")
        # the response object was not set. The error lies in the network connection or
        # some other cause.

        # Display a generic error message.
        $sectionNoticeError.empty()
        $sectionNoticeError.append($sectionNoticeErrorString)
      else
        $nodeArray = []
        # Display the JSON-encoded error log.
        $nodeArray.push('<div class="block-spacing">')
        $nodeArray.push('<ul class="bullet">')

        # Insert the returned errors into the error section.
        $.each(optionalResponse, (k, v) ->
          # Skip the validation_result boolean signal
          if (k == "submit_result")
              return true
          $nodeArray.push('<li>' + v + '</li>')
        )

        $nodeArray.push('</ul>')
        $nodeArray.push('</div>')

        # Insert the new node into the page.
        $sectionNoticeError.empty()
        $sectionNoticeError.append($nodeArray.join(''))

        # Show the actual comment error section.
        $sectionNoticeError.removeClass("hiddenBox")
        $sectionNoticeSuccess.addClass("hiddenBox")

  ###
  Callback function invoked when an AJAX request has been completed via the preview button.
  ###
  submit_preview_request = (isValidSubmit, optionalResponse) ->

    # Handle output based on response.
    if (isValidSubmit)

      # Set the preview comment state.
      setCommentState(MODE_PREVIEW)

      # Insert the server validated content into the preview content section.

      # Insert the comment content.
      $sectionPreviewContent.empty()
      $sectionPreviewContent.append(optionalResponse.comment)

      $nodeArray = []

      # If name contains no input...
      if (!optionalResponse.name)
        optionalResponse.name = "Anonymous"

      # If the link contains input...
      if (optionalResponse.link)
        # Add a link to the name.
        $nodeArray.push('<a href="')
        $nodeArray.push(optionalResponse.link)
        $nodeArray.push('">')
        $nodeArray.push(optionalResponse.name)
        $nodeArray.push('</a>')
      else
        # Just add the name.
        $nodeArray.push(optionalResponse.name)

      # Insert the author.
      $sectionPreviewAuthor.empty()
      $sectionPreviewAuthor.append($nodeArray.join(''))

      # Insert the datetime.
      $sectionPreviewDatetime.empty()
      $sectionPreviewDatetime.append(optionalResponse.date)
    else
      # If the JSON object is set (there was a response from the server).
      # This means server-side validation has failed.
      if (typeof optionalResponse == "undefined")
        # the response object was not set. The error lies in the network connection or
        # some other cause.

        # Display a generic error message.
        $sectionNoticeError.empty()
        $sectionNoticeError.append(
          '<p class="comments-open-subtext">' +
              'There was a problem loading the preview.' + '</p>'
        )
      else
        # Display the JSON-encoded error log.
        $nodeArray = []
        $nodeArray.push('<div class="block-spacing">')
        $nodeArray.push('<ul class="bullet">')

        # Insert the returned errors into the error section.
        $.each(optionalResponse, (k, v) ->
          # Skip the validation_result boolean signal
          if (k == "submit_result")
              return true
          $nodeArray.push('<li>' + v + '</li>')
        )

        $nodeArray.push('</ul>')
        $nodeArray.push('</div>')

        # Insert the new node into the page.
        $sectionNoticeError.empty()
        $sectionNoticeError.append($nodeArray.join(''))

      # Show the actual comment error section.
      $sectionNoticeError.removeClass("hiddenBox")
      $sectionNoticeSuccess.addClass("hiddenBox")

  ###
  Callback function invoked when an AJAX request has been completed.
  ###
  validate_email_request = (isValidEmail) ->
    # If the email is not valid...
    if (!isValidEmail)
      # Display an error message.
      $fieldEmail.addClass("comment-error")

      # Remove the hidden class from span.
      $emailInfo.removeClass("hiddenBox")

      return false

    # Remove the error message.
    $fieldEmail.removeClass("comment-error")

    # Add the hidden class to span.
    $emailInfo.addClass("hiddenBox")

    return true

  ###
  Callback function invoked when an AJAX request has been completed.
  ###
  validate_link_request = (isValidLink) ->

    # If the link is not valid...
    if (!isValidLink)

      # Display an error message.
      $fieldLink.addClass("comment-error")

      # Remove the hidden class from span.
      $linkInfo.removeClass("hiddenBox")

      return false

    # Remove the error message.
    $fieldLink.removeClass("comment-error")

    # Add the hidden class to span.
    $linkInfo.addClass("hiddenBox")

    return true

  ###
  Validation functions.
  ###

  ###
  Performs validation on the comment field. Mirrors server-side validation.
  ###
  validateComment = () ->

    # If the textarea contains no input...
    if (!$fieldComment.val())
      # Disable the buttons
      $buttonPost.attr("disabled", "disabled")
      $buttonPreview.attr("disabled", "disabled")

      # Display an error message.
      $fieldComment.addClass("comment-error")
      $isCommentValid = false
    else
      # Enable the buttons.
      $buttonPost.removeAttr("disabled")
      $buttonPreview.removeAttr("disabled")

      # Remove the error message.
      $fieldComment.removeClass("comment-error")
      $isCommentValid = true

  ###
  Performs validation on the name field. Mirrors server-side validation.
  ###
  validateName = () ->
    # Blank names are anonymous
    # No validation required
    $isNameValid = true

  ###
  Performs validation on the email field. Delegates validation check to the server.
  Validates on server failure. Pure server-side validation is the contingency.
  ###
  validateEmail = () ->

    # Abort any pending requests
    if ($request_validate_email)
        $request_validate_email.abort()

    # serialize the data in the field
    serializedData = $fieldEmail.serialize()

    $request_validate_email = $.ajax({
      url: $ajax_file,
      type: "post",
      data: serializedData + "&invoke=validate_email",
      dataType: "json"
    })

    # callback handler that will be called on success
    $request_validate_email.done( (response) ->
      $isEmailValid = (validate_email_request(response.validate_result))
    )

    # callback handler that will be called on failure
    $request_validate_email.fail( () ->
      $isEmailValid = (validate_email_request(1))
    )

  ###
  Performs validation on the link field. Delegates validation check to the server.
  Validates on server failure. Pure server-side validation is the contingency.
  ###
  validateLink = () ->

    # Abort any pending requests
    if ($request_validate_link)
      $request_validate_link.abort()

    # serialize the data in the field
    serializedData = $fieldLink.serialize()

    $request_validate_link = $.ajax({
      url: $ajax_file,
      type: "post",
      data: serializedData + "&invoke=validate_link",
      dataType: "json"
    })

    # callback handler that will be called on success
    $request_validate_link.done( (response) ->
      $isLinkValid = (validate_link_request(response.validate_result))
    )

    # callback handler that will be called on failure
    $request_validate_link.fail( () ->
      $isLinkValid = (validate_link_request(1))
    )

  ###
  Form bootstrap.
  ###

  # Determines which form to use. Currently the code is designed for one form per page.
  # If more is needed, just update this identification code to bind all events to each
  # of the forms as required.
  if ($commentForm.length)
    $formComment = $commentForm

    $sectionNoticeErrorString = '<p class="comments-open-subtext">' +
                    'There was a problem submitting your comment.' + '</p>'
  else if ($contactForm.length)
    $formComment = $contactForm

    $sectionNoticeErrorString = '<p class="comments-open-subtext">' +
                    'There was a problem submitting your message.' + '</p>'

  # Only run if a form exists
  if ($formComment)
    ###
    Event Handling.
    ###

    # Bind change listeners to each form field input.
    # We're using add instead of multiple selectors for <=IE7 compatibility.
    $formComment.find("input[type=text]").add("textarea").each( () ->

      elem = $(this)

      # Save current value of element
      elem.data('oldVal', elem.val())

      # Look for changes in the value
      elem.bind("propertychange keyup input paste", () ->
        # If value has changed...
        if (elem.data('oldVal') != elem.val())
          # Updated stored value
          elem.data('oldVal', elem.val())

          # Do action based on the field changed.
          switch (elem.attr("id"))

            when "comment-text"

              validateComment()

            when "comment-author"

              validateName()

            when "comment-email"

              validateEmail()

            when "comment-url"

              validateLink()

        )
    )

    # Attach a click event listener to the post button.
    $buttonPost.click( () ->
      $submit = "post"

      # Submit the form only if all validation checks are passed.
      # Use boolean flags (built on-the-fly) for async ajax call compatibility.
      if ($isCommentValid && $isNameValid && $isEmailValid && $isLinkValid)
        return true

      # Invoke all validation methods to give the user some feedback.
      validateComment()
      validateName()
      validateEmail()
      validateLink()

      return false
    )

    # Attach a click event listener to the preview button.
    $buttonPreview.click( () ->
      $submit = "preview"

      # Submit the form only if all validation checks are passed.
      if ($isCommentValid && $isNameValid && $isEmailValid && $isLinkValid)
        return true

      # Invoke all validation methods to give the user some feedback.
      validateComment()
      validateName()
      validateEmail()
      validateLink()

      return false
    )

    # Attach a click event listener to the confirm button.
    $buttonConfirm.click( () ->
      $submitPreview = "confirm"

      # Submit the form only if all validation checks are passed.
      if ($isCommentValid && $isNameValid && $isEmailValid && $isLinkValid)
          return true

      # Invoke all validation methods to give the user some feedback.
      validateComment()
      validateName()
      validateEmail()
      validateLink()

      return false
    )

    # Attach a click event listener to the edit button.
    $buttonEdit.click( () ->
      $submitPreview = "edit"

      # Submit the form only if all validation checks are passed.
      # Use boolean flags (built on-the-fly) for async ajax call compatibility.
      if ($isCommentValid && $isNameValid && $isEmailValid && $isLinkValid)
          return true

      # Invoke all validation methods to give the user some feedback.
      validateComment()
      validateName()
      validateEmail()
      validateLink()

      return false
    )

    $formComment.submit( (event) ->
      # Abort any pending requests
      if ($request_submit)
        $request_submit.abort()

      # Start the spinner.
      $spinner.removeClass("hiddenBox")

      # let's select and cache all the fields
      $inputs = $formComment.find("input, select, button, textarea")
      # serialize the data in the form
      serializedData = $formComment.serialize()

      # let's disable the inputs for the duration of the ajax request
      $inputs.prop("disabled", true)

      $request_submit = $.ajax({
        url: $ajax_file,
        type: "post",
        data: serializedData + "&submit=" + $submit,
        dataType: "json"
      })

      # callback handler that will be called on success
      $request_submit.done( (response) ->
        # reenable the inputs
        $inputs.prop("disabled", false)
        # Respond based on the button clicked.
        switch ($submit)
          when "post"
            submit_post_request(response.submit_result, response)

          when "preview"
            submit_preview_request(response.submit_result, response)
      )

      # callback handler that will be called on failure
      $request_submit.fail( () ->
        # reenable the inputs
        $inputs.prop("disabled", false)
        # Respond based on the button clicked.
        switch ($submit)
          when "post"
            submit_post_request(0)

          when "preview"
            submit_preview_request(0)

      )

      # callback handler that will be called regardless
      # if the request failed or succeeded
      $request_submit.always( () ->
        # Stop the spinner.
        $spinner.addClass("hiddenBox")
      )

      # prevent default posting of form
      event.preventDefault()
    )

    # Attach a form submission event handler to the preview form.
    $formPreview.submit( (event) ->

      # Respond based on the button clicked.
      switch ($submitPreview)
        when "confirm"

          # Abort any pending requests
          if ($request_preview)
            $request_preview.abort()

          # Start the spinner.
          $spinnerPreview.removeClass("hiddenBox")

          # let's select and cache all the fields
          $inputs = $formComment.find("input, select, button, textarea")
          # serialize the data in the form
          serializedData = $formComment.serialize()

          # let's disable the inputs for the duration of the ajax request
          $inputs.prop("disabled", true)

          $request_preview = $.ajax({
            url: $ajax_file,
            type: "post",
            data: serializedData + "&submit=post",
            dataType: "json"
          })

          # callback handler that will be called on success
          $request_preview.done( (response) ->
            # reenable the inputs
            $inputs.prop("disabled", false)
            # Set the edit comment state.
            setCommentState(MODE_EDIT)
            # Respond based on the button clicked.
            submit_post_request(response.submit_result, response)
          )

          # callback handler that will be called on failure
          $request_preview.fail( () ->
            # reenable the inputs
            $inputs.prop("disabled", false)
            # Set the edit comment state.
            setCommentState(MODE_EDIT)
            submit_post_request(0)
          )

          # callback handler that will be called regardless
          # if the request failed or succeeded
          $request_preview.always( () ->
            # Stop the spinner.
            $spinnerPreview.addClass("hiddenBox")
          )

        when "edit"

          # Set the edit comment state.
          setCommentState(MODE_EDIT)

      # prevent default posting of form
      event.preventDefault()

    )

    ###
    Display comment form.
    ###

    # Show the actual comment input area.
    $('#comments-open-text').show()
    # Show the user data input area.
    $('#comments-open-data').show()
    # Show the submit area.
    $('#comments-open-footer').show()

)
