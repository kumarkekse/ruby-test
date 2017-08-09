#Refactored code
# Annotate or propose how you'd improve the code for readability/maintainability

class MissionsController < ApplicationController

  def index
    mission_search_object = MissionSearch.new( current_program, current_company )

    @mission_types = mission_search_object.mission_types

    @featured_present = mission_search_object.featured_present?

    @missions, @mission_type = mission_search_object.filter( params )
  end
end


class MissionSearch

  attr_accessor :current_program, :current_company, :missions

  def initialize( current_program, current_company )
    @current_program = current_program
    @current_company = current_company
    @missions = all_missions
  end

  def filter( params )
    mission_type = nil
    if params[:mission_type_id].present? && !sponsored?
      @missions , mission_type = filter_by_type( params[:mission_type_id] )
    elsif params[:search].blank?
      @missions , mission_type = simple_filter
    end

    @missions = filter_by_name( params[:search] ) if params[:search].present?
    @missions = @missions.includes(:milestones)
    @missions = @missions.sponsored if sponsored?
    @missions = @missions.order( 'missions.position asc, missions.mission_date asc, missions.name asc, missions.id desc' )

    @missions, mission_type
  end


  def simple_filter
    mission_type = nil
    if featured_present?
      @missions = @missions.featured.with_mission_type_id( mission_type_ids )
    else
      mission_type = mission_types.first
      @missions = @missions.with_mission_type_id( mission_type_ids & [ mission_type.id ] )
    end

    @missions, mission_type
  end
  

  def filter_by_type( mission_type_id )
    @missions = @missions.with_mission_type_id( mission_type_ids & Array(mission_type_id).map(&:to_i) )
    mission_type = MissionType.where( id: params[:mission_type_id] ).first
    
    @missions , mission_type
  end

  def all_missions
    @current_company.missions_for_program( @current_program )
                  .includes(:company, :mission_type, :survey => {:questions => [:translations, {:answers => :translations }] })
  end
  
  def filter_by_name( name )
    @missions.where('UPPER(name) LIKE ?', "%#{name.upcase}%")
  end

  def featured_present?
    @missions.exists?(featured: true)
  end

  def mission_types
    MissionType.prioritised.where( id: mission_type_ids )
  end

  def mission_type_ids
    mission_type_ids = (
      @current_company.missions_for_program(@current_program).pluck("distinct(mission_type_id)") #+
    ).uniq
  end
end