function save_incident(draft, add_patron){
    var params = {}
    params['title'] = $('#title').val()
    params['description'] = $('#description').val()
    params['date_of'] = picker.viewDate
    params['location'] = $('#location').val()
    if(draft == 'true'){
        params['draft'] = true
    }
    if(add_patron == 'true'){
        params['add_patron'] = true 
    }
    if($('#no_patrons').is(':checked')){
        params['no_patrons'] = true 
    }
    params['incident_id'] = $('#incident_id').html()
    
    var incident_params = new FormData()
    $.each(params, function(k,v){
        incident_params.append(k, v)
    });

    var incident_images = $('#incident_images').prop("files");
    if(incident_images && incident_images[0]){
        $.each(incident_images, function(i){
            incident_params.append('images[]', this)
        });
    }

    $.ajax({
        url: "/incidents/save.js",
        data: incident_params,
        type:'POST',
        contentType: false,
        processData: false,
    });

    if(add_patron == 'true'){
        $('#save_incident_buttons').hide()
    }
}
window.save_incident = save_incident

function delete_incident_image(image_id){
    var params = {}
    params['incident_id'] = $('#incident_id').html()
    params['image_id'] = image_id
    $.post("/incidents/delete_image.js", params);
}
window.delete_incident_image = delete_incident_image

function cancel_incident_images(){
    $('#incident_images').val(null)
}
window.cancel_incident_images = cancel_incident_images

function search_incidents(){
    var query = $('#query').val()
    window.location.href = '/incidents/search?query=' + query
}
window.search_incidents = search_incidents

function delete_incident(incident_id){
    var confirmation = confirm("Are you sure you want to delete this incident?")
    if(confirmation == true){
        var params = {}
        params['id'] = incident_id
        $.post("/incidents/delete_incident.js", params);
    }
}
window.delete_incident = delete_incident