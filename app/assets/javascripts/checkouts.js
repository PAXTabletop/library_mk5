$(document).ready(function(){

    // Make a call to /attendee/status when a new barcode is entered.
    $('#a-barcode').change(function(){
        var barcode_val = $(this).val();

        if(!bc_regex.test(barcode_val)){
            addNote('Invalid barcode format! Format should be like PAX####PA.', 'warning', 3000);
            $(this).val('');
            return;
        }
        attendeeBarcode(false);

        $.get('attendee/status', { barcode: barcode_val }).success(function(response){
            $('#a-name').text(response.attendee.name);
            $('#g-row').show();
            $('#g-barcode').focus();
            displayCheckouts(response.checkouts);
        }).error(function(response){
            if(response.status == 400){
                $('#a-form').modal();
            }else{
                addNote(DEFAULT_ERROR, 'danger');
                attendeeBarcode(true);
            }
        });
    });

    // Reset the view when the X button is clicked.
    $('#checkouts-x-btn').click(function(){
        resetCheckout();
    });

    // Clear all attendee form fields when the form is hidden.
    $('#a-form').on('hidden.bs.modal', function(){
        $('#a-form').find('input').val('');
    }).on('shown.bs.modal', function(){
        $('#a-form').find('[name="first_name"]').focus();
    });

    // Hide form, clear attendee barcode field on cancel click.
    $('#a-form-cancel').click(function(){
        $('#a-form').modal('hide');
        attendeeBarcode(true);
    });

    // Submit new attendee information. On success, hide form and display new info.
    $('#a-form-save').click(function(){
        var data = $('#a-form').find('.form-control').serializeArray();
        data.push({
            name: 'barcode',
            value: $('#a-barcode').val()
        });
        $('#a-form').find('input').parent().removeClass('has-error').find('.glyphicon').hide();
        $.post('attendee/new', data).success(function(response){
            if(response.attendee){
                $('#a-form').modal('hide');
                $('#a-name').text(response.attendee.name);
                $('#g-row').show();
                $('#g-barcode').focus();
            }else{
                // got errors
                $.each(response.errors, function(k, v){
                    var input = $('[name="' + k + '"]');

                    input.parent().addClass('has-error');
                    input.siblings('.glyphicon').show();
                });
            }
        }).error(function(){

        });
    });

    $('#g-barcode').change(function(){
        var barcode_val = $(this).val();

        if(!bc_regex.test(barcode_val)){
            addNote('Invalid barcode format! Format should be like TTL####TT.', 'warning', 3000);
            $(this).val('');
            return;
        }

        $.post('checkout/new', { g_barcode: barcode_val, a_barcode: $('#a-barcode').val() }).success(function(response){
            if(response.errors){
                $.each(response.errors, function(k, v){
                    // FIXME: Weird error of "can't be blank" comes back when entering a non-existant game barcode
                    addNote(v, 'danger');
                });
            }else if(response.checkouts.length == 1){
                addNote('Game successfully checked out!');
                resetCheckout();
            }else{
                addNote('Game successfully checked out!');
                displayCheckouts(response.checkouts);
            }
        }).error(function(){
            addNote(DEFAULT_ERROR, 'danger');
        }).complete(function(){
            $('#g-barcode').val('');
        });
    });

    $('#games-container').delegate('.return-game', 'click', function(){
        var _me = $(this);
        $.post('/return', { co_id: _me.data('checkout-id') }).success(function(){
            addNote('Returned game successfully!');
            _me.closest('.row').remove();
            if($('#games-container').children().length <= 0){
                resetCheckout();
            }
        }).error(function(){
            addNote(DEFAULT_ERROR, 'danger');
        });
    });

    $('#find-barcode').change(function(){
        $.get('/find', $(this).serialize(), null, 'script');
    });

});

function attendeeBarcode(bool){
    var barcode = $('#a-barcode');

    barcode.prop('disabled', !bool);
    if(bool){
        barcode.val('').focus();
    }
    $('#checkouts-x-btn').toggle(!bool);
}

function resetCheckout(){
    attendeeBarcode(true);
    $('#a-name').text('');
    $('#g-barcode').val('');
    $('#g-row').hide();
    $('#games-container').html('');
}

function displayCheckouts(checkouts){
    var container = $('#games-container');
    container.html('');
    $.each(checkouts, function(o, v){
        container.append(v);
    });
}