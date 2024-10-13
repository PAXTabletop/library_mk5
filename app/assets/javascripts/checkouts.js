$(document).ready(function(){

    // Make a call to /return when a new barcode is entered.
    $('#g-barcode').change(function(){
        var barcode_val = $(this).val();

        if(!bc_regex.test(barcode_val)){
            $.notify('Invalid barcode format! Barcode should be at least 3 characters long and only contain alphanumeric characters.', 'warning', 5000);
            $(this).val('');
            return;
        }
        gameBarcode(false);

        $.post('/return', { barcode: barcode_val }).success(function(response){
            if(response.errors){
                $.each(response.errors, function(k, v){
                    $.notify(v, 'danger');
                });
                gameBarcode(true);
            }else if(response.time){
                $.notify('Successfully returned ' + response.game + '!', 5000);
                resetCheckout();
            }else{
                $('#g-name').text('Checking out: ' + response.game)
                $('#a-row').show();
                $('#a-barcode').focus();
            }
        }).error(function(){
            $.notify(DEFAULT_ERROR, 'danger');
            gameBarcode(true);
        });
    });

    // Make a call to /attendee/status when a new barcode is entered.
    $('#a-barcode').change(function(){
        var barcode_val = $(this).val();

        if(!bc_regex.test(barcode_val)){
            $.notify('Invalid barcode format! Barcode should be at least 3 characters long and only contain alphanumeric characters.', 'warning', 5000);
            $(this).val('');
            return;
        }
        attendeeBarcode(false);

        $.get('attendee/status', { barcode: barcode_val }).success(function(response){
            $.post('checkout/new', { g_barcode: $('#g-barcode').val(), a_barcode: barcode_val }).success(function(response){
                if(response.errors){
                    $.each(response.errors, function(k, v){
                        $.notify(v, 'danger');
                    });
                }else{
                    $.notify('Successfully checked out ' + response.game + '!');
                    resetCheckout();
                }
                if(response.approval){
                    $.notify(response.approval, 'success', 8000);
                }
            }).error(function(){
                $.notify(DEFAULT_ERROR, 'danger');
            }).complete(function(){
                attendeeBarcode(true);
            });
        }).error(function(response){
            if(response.status == 400){
                saveAttendee();
            }else{
                $.notify(DEFAULT_ERROR, 'danger');
                attendeeBarcode(true);
            }
        });
    });

    // Reset the view when the X button is clicked.
    $('#checkouts-x-btn').click(function(){
        resetCheckout();
    });

    $('#find-barcode').change(function(){
        $.get('/find', $(this).serialize(), null, 'script');
    });

    $('#found-div').delegate('.return-game', 'click', function(){
        var _me = $(this);
        $.post('/return', { co_id: _me.data('checkout-id') }).success(function(response){
            $.notify('Successfully returned ' + response.game + '!', 5000);
            var cell = _me.closest('.col-xs-2');
            cell.html(response.time);
            cell.next().html("RETURNED");
        }).error(function(){
            $.notify(DEFAULT_ERROR, 'danger');
        });
    });
});

function gameBarcode(active){
    var barcode = $('#g-barcode');

    barcode.prop('disabled', !active);
    if(active){
        barcode.val('').focus();
    }
    $('#checkouts-x-btn').toggle(!active);
}

function attendeeBarcode(active){
    var barcode = $('#a-barcode');

    if(active){
        barcode.val('').focus();
    }
}

// Submit new attendee information. On success, hide form and display new info.
function saveAttendee(){
    $.post('attendee/new', { barcode: $('#a-barcode').val() }).success(function(response){
        if(response.attendee){
            $.post('checkout/new', { g_barcode: $('#g-barcode').val(), a_barcode: $('#a-barcode').val() }).success(function(response){
                if(response.errors){
                    $.each(response.errors, function(k, v){
                        $.notify(v, 'danger');
                    });
                }else{
                    $.notify('Successfully checked out ' + response.game + '!');
                    resetCheckout();
                }
                if(response.approval){
                    $.notify(response.approval, 'success', 8000);
                }
            }).error(function(){
                $.notify(DEFAULT_ERROR, 'danger');
            }).complete(function(){
                attendeeBarcode(true);
            });
        } else {
            $.notify(DEFAULT_ERROR, 'danger');
            attendeeBarcode(true);
        }
    }).error(function(){
        $.notify(DEFAULT_ERROR, 'danger');
        attendeeBarcode(true);
    });
};

function resetCheckout(){
    gameBarcode(true);
    $('#g-name').text('');
    $('#g-barcode').val('');

    attendeeBarcode(false);
    $('#a-row').hide();
    $('#a-barcode').val('');
}