var lastBarcode;

$(document).ready(function(){
    $('#g-barcode, #a-barcode').focus(function(){
        lastBarcode = $(this);
    });

    $('#g-barcode, #a-barcode').blur(function(){
        var barcode = $(this);
        setTimeout(function(){
            if($('#suggest-form').is(':visible')){
                return;
            }
            if(barcode.is(':visible') && !barcode.prop('disabled')){
                barcode.focus();
            }
        }, 0);
    });

    // Use the page-specific checkout or return API when a game barcode is entered.
    $('#g-barcode').change(function(){
        var barcode_val = $(this).val();

        if(!bc_regex.test(barcode_val)){
            $.notify('Invalid barcode format! Barcode should be at least 3 characters long and only contain alphanumeric characters.', 'warning', 5000);
            $(this).val('');
            return;
        }
        gameBarcode(false);

        var checkoutMode = $('#checkout-page').length > 0;
        var returnMode = $('#return-page').length > 0;
        var statusRequest = checkoutMode ? $.post('/checkout/new', { g_barcode: barcode_val }) : $.post('/return', { barcode: barcode_val });

        statusRequest.success(function(response){
            if(response.errors){
                $.each(response.errors, function(k, v){
                    $.notify(v, 'danger');
                });
                gameBarcode(true);
            }else if(returnMode){
                if(response.time){
                    $.notify('Successfully returned ' + response.game + '!', 5000);
                }else if(response.storage_removed){
                    $.notify('Removed ' + response.game + ' from storage.', 5000);
                }else{
                    $.notify(response.game + ' is not currently checked out.', 'warning', 5000);
                }
                resetCheckout();
            }else{
                if(checkoutMode && response.cleared){
                    $.notify('Previously active checkout or loan cleared for ' + response.game + '.', 5000);
                }
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
            $.post('/checkout/new', { g_barcode: $('#g-barcode').val(), a_barcode: barcode_val }).success(function(response){
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

function restoreBarcodeFocus(){
    if(lastBarcode && lastBarcode.is(':visible') && !lastBarcode.prop('disabled')){
        lastBarcode.focus();
    }else{
        gameBarcode(true);
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