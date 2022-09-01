class AdminController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_user!
    before_action :check_super_admin!
    
    def new_rule
        @action = 'Creating New '
        @rule = Rule.new
        respond_to do |format|
            format.js
        end
    end
    
    def edit_rule
        @action = 'Editing '
        id = params[:id].to_i
        @rule = Rule.find(id)
        respond_to do |format|
            format.js
        end
    end 

    def save_rule
        if params[:id]
            id = params[:id].to_i
            @rule = Rule.find(id)
        else
            @rule = Rule.new
        end
        if @rule
            @rule.assign_attributes(rule_params)
            if @rule.valid?
                @rule.save
                @updated = true
            else
                @updated = false
            end
        else
            @updated = false 
        end
        respond_to do |format|
            format.js
        end
    end

    private

    def rule_params
        params.permit(:legacy, :description, :track)
    end

end