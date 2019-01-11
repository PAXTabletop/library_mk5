var titleDataSource = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        prefetch: '../titles.json'
    }),
    publisherDataSource = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        prefetch: '../publishers.json'
    });

$(document).ready(function(){

    // Hide form, clear game barcode field on cancel click.
    $('#g-form-cancel').click(function(){
        $('#g-form').modal('hide');
        adminBarcode(true);
    });

    // Make a call to /attendee/status when a new barcode is entered.
    $('#new-g-barcode').change(function(){
        var barcode_val = $(this).val();

        if(!bc_regex.test(barcode_val)){
            $.notify('Invalid barcode format! Barcode should be at least 7 characters long and only contain alphanumeric characters.', 'warning', 5000);
            $(this).val('');
            return;
        }
        adminBarcode(false);

        $.get('/game/status', { barcode: barcode_val }).success(function(response){
            $.get('/game/display', { barcode: barcode_val, message: response.message }, null, 'script');
            adminBarcode(true);
        }).error(function(response){
            if(response.status == 400){
                $('#g-form').modal();
            }else{
                $.notify(DEFAULT_ERROR, 'danger');
                adminBarcode(true);
            }
        });
    }).on('input', function(){
        $('#g-name').html('');
    });

    // Submit new game information. On success, hide form and display new info.
    var saveGame = function(){
            var data = $('#g-form').find('input').serializeArray(),
                barcode_val = $('#new-g-barcode').val();
            data.push({
                name: 'barcode',
                value: barcode_val
            });
            $('#g-form').find('input').parent().removeClass('has-error').find('.glyphicon').hide();
            $.post('/game/new', data).success(function(response){
                if(response.game){
                    $('#g-form').modal('hide');
                    $.get('/game/display', { barcode: barcode_val, message: response.game.name + ' successfully added!' }, null, 'script');
                    adminBarcode(true);

                    titleDataSource.clearPrefetchCache();
                    titleDataSource.initialize(true);
                    publisherDataSource.clearPrefetchCache();
                    publisherDataSource.initialize(true);
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
        },
        saveGameByEnter = function(e){
            if(e.keyCode === 13 && $('#g-form').is(':visible')){
                saveGame();
            }
        };
    $('#g-form-save').click(saveGame);
    $('#g-form').find('input[type="text"]').keypress(saveGameByEnter);

    // Clear all attendee form fields when the form is hidden.
    $('#g-form').on('hidden.bs.modal', function(){
        $('#g-form').find('input').val('').prop('checked', false);
    }).on('shown.bs.modal', function(){
        $('#g-form').find('[name="title"]').focus();
    });

    $('[name="title"]').typeahead({
        minLength: 1,
        highlight: true,
        hint: false
    },{
        source: titleDataSource
    });

    $('[name="publisher"]').typeahead({
        minLength: 1,
        highlight: true,
        hint: false
    },{
        source: publisherDataSource
    });

});

function adminBarcode(bool){
    var barcode = $('#new-g-barcode');

    barcode.prop('disabled', !bool);
    if(bool){
        barcode.val('').focus();
    }
}