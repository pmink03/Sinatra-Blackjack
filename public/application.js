$(document).ready(function() {
	
	$(document).on('click', '#hit_button', function() {
		$.ajax( {
			type: 'POST',
			url: '/game/player/hit'
		}).done(function(msg) {
			$('#game').replaceWith(msg);
		});
		return false;
	});

	$(document).on('click', '#stay_button', function() {
		$.ajax( {
			type: 'POST',
			url: '/game/player/stay'
		}).done(function(msg) {
			$('#game').replaceWith(msg);
		});
		return false;
	});

	$(document).on('click', '#dealer_button', function() {
		$.ajax( {
			type: 'POST',
			url: '/game/dealer'
		}).done(function(msg) {
			$('#game').replaceWith(msg);
		});
		return false;
	});


});