$(document).ready(function() {
	// Login form
	$('#login_link').click(function() {
		$(this).fadeOut('fast', function() {
			$('#login_form').fadeIn('normal', function() {
				$('#login_form .login').focus();
			});
		});
		return false;
	});
});
