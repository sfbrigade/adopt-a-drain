$(document).on('click', '.toggle-password', function() {
  $(this).toggleClass("fa-eye fa-eye-slash");
  var input = $($(this).attr("toggle"));
  if (input.attr("type") == "password") {
    input.attr("type", "text");
    console.log("test1")
  } else {
    console.log("test12")
    input.attr("type", "password");
  }
});

