# ruby-test
Test work to refactoring ruby code

# Annotate or propose how you'd improve the code for readability/maintainability


class MissionsController < ApplicationController

  def index
    mission_type_ids = (
      current_company.missions_for_program(current_program).pluck("distinct(mission_type_id)") #+
    ).uniq

    @mission_types = MissionType.prioritised.where id: mission_type_ids


    @missions = current_company.missions_for_program(current_program)
                  .includes(:company, :mission_type, :survey => {:questions => [:translations, {:answers => :translations }] })

    @featured_present = @missions.exists?(featured: true)
    # Filter to single intersecting mission_type if param is present:
    if params[:mission_type_id].present? && !sponsored?
      @missions = @missions.with_mission_type_id (mission_type_ids & Array(params[:mission_type_id]).map(&:to_i))
      @mission_type = MissionType.where(id: params[:mission_type_id]).first
    elsif params[:search].blank?
      if @featured_present
        @missions = @missions.featured.with_mission_type_id @mission_types.pluck(:id)
      else
        @mission_type = @mission_types.first
        params[:mission_type_id] = @mission_type.id
        @missions = @missions.with_mission_type_id (mission_type_ids & [@mission_type.id])
      end
    end

    @missions = @missions.where('UPPER(name) LIKE ?', "%#{params[:search].upcase}%") if params[:search].present?
    @missions = @missions.sponsored                                               if sponsored?
    @missions = @missions.order 'missions.position asc, missions.mission_date asc, missions.name asc, missions.id desc'
    @missions = @missions.includes(:milestones)
  end
end
