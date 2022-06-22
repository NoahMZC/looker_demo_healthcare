include: "person.view.lkml"

## Example A: Step 2: Building the cohort

view: cross_join {

  parameter: codeset_custom {
    hidden: yes
    type: unquoted
    suggest_explore: concept_occurrence
    suggest_dimension: concept.concept_id
    default_value: "4094876"
  }

  dimension: is_codeset_custom {
    group_label: "Rules - Cohort"
    type: yesno
    sql:
      ${concept.concept_id} in ({% parameter codeset_custom %})
      OR
      (
        ${concept_ancestor.ancestor_concept_id} in ({% parameter codeset_custom %})
        AND
        ${concept.invalid_reason} is null
      )
      ;;
  }

  dimension: codeset_0 {
    group_label: "Rules - Cohort"
    label: "Lung Cancer Conditions (Primary)"
    type: string
    sql: 4094876,4334322,4092217,4311499 ;;
  }

  dimension: is_codeset_0 {
    group_label: "Rules - Cohort"
    label: "Lung Cancer Conditions (Primary)"
    type: yesno
    sql:
      ${concept.concept_id} in ${codeset_0}
      OR
      (
        ${concept_ancestor.ancestor_concept_id} in ${codeset_0}
        AND
        ${concept.invalid_reason} is null
      )
      ;;
  }

  dimension: codeset_1 {
    group_label: "Rules - Cohort"
    label: "Lung Cancer Conditions (Secondary)"
    type: string
    sql: 193144,78097,378087,140960,201240,192568,200959,439751,196053,40492474,198700,254591,318096,442182,320342,442181,434298,434875,373425,199752,72266,4147162,253717,196925,136354,198371,442173,78987,432851 ;;
  }

  dimension: is_codeset_1 {
    group_label: "Rules - Cohort"
    label: "Lung Cancer Conditions (Secondary)"
    type: yesno
    sql:
      ${concept.concept_id} in ${codeset_1}
      OR
      (
        ${concept_ancestor.ancestor_concept_id} in ${codeset_1}
        AND
        ${concept.invalid_reason} is null
      )
      ;;
  }

  dimension: is_over_18 {
    group_label: "Rules - Cohort"
    label: "Is Over 18 (@ Condition Start)"
    type: yesno
    sql: ${condition_occurrence.condition_start_year} - ${person.year_of_birth} > 18  ;;
  }

  dimension: is_included {
    group_label: "Rules - Cohort"
    type: yesno
    sql: ${all_inclusions.inclusion} is not null ;;
  }
}

view: primary_events {
  derived_table: {
    datagroup_trigger: once_monthly
    explore_source: condition_occurrence {
      column: person_id {}
      column: condition_start_date {}
      column: condition_end_revised_date {}
      column: observation_period_start_date { field: observation_period.observation_period_start_date }
      column: observation_period_end_date { field: observation_period.observation_period_end_date }
      column: visit_occurrence_id {}
      filters: {
        field: cross_join.is_codeset_0
        value: "Yes"
      }
      derived_column: ordinal_rank {
        sql: row_number() OVER (partition by person_id ORDER BY condition_start_date) ;;
      }
    }
  }
  dimension: pk {
    primary_key: yes
    hidden: yes
    type: string
    sql: concat(${person_id},${visit_occurrence_id}) ;;
  }
  dimension: person_id {
    hidden: yes
    type: number
  }
  dimension: condition_start_date {
    hidden: yes
    type: date
  }
  dimension: condition_end_revised_date {
    hidden: yes
    type: date
  }
  dimension: observation_period_start_date {
    hidden: yes
    type: date
  }
  dimension: observation_period_end_date {
    hidden: yes
    type: date
  }
  dimension: visit_occurrence_id {
    hidden: yes
    type: number
  }
  dimension: ordinal_rank {
    group_label: "Rules - Cohort"
    label: "Event ID"
    description: "Ordinal Rank"
    type: number
  }
  dimension: is_primary_event {
    group_label: "Rules - Cohort"
    type: yesno
    sql: ${ordinal_rank} = 1 ;;
  }
  measure: count {
    hidden: yes
    type: count
  }
  measure: count_pk {
    hidden: yes
    type: count_distinct
    sql: ${pk} ;;
  }
}

view: inclusion_0 {
  derived_table: {
    datagroup_trigger: once_monthly
    explore_source: condition_occurrence {
      column: person_id {}
      column: ordinal_rank { field: primary_events.ordinal_rank }
      derived_column: inclusion {
        sql: 'Lung Cancer Cohort' ;;
      }
      filters: {
        field: cross_join.is_over_18
        value: "Yes"
      }
    }
  }

  dimension: pk {
    hidden: yes
    primary_key: yes
    sql: concat(${inclusion},${person_id}) ;;
  }
  dimension: inclusion {
    label: "Cohort Name"
    type: string
  }
  dimension: person_id {
    hidden: yes
    type: number
  }
  dimension: ordinal_rank {
    hidden: yes
    label: "Event ID"
    description: "Ordinal Rank"
    type: number
  }
  measure: count {
    hidden: yes
    type: count
  }
  measure: count_pk {
    hidden: yes
    type: count_distinct
    sql: ${pk} ;;
  }
}

view: inclusion_1 {
  derived_table: {
    datagroup_trigger: once_monthly
    explore_source: condition_occurrence {
      column: person_id {}
      column: ordinal_rank { field: primary_events.ordinal_rank }
      derived_column: inclusion {
        sql: 'Lung Cancer Cohort' ;;
      }
      filters: {
        field: cross_join.is_codeset_1
        value: "Yes"
      }
      filters: {
        field: condition_occurrence.count_concept_id
        value: ">1"
      }
    }
  }

  dimension: pk {
    hidden: yes
    primary_key: yes
    sql: concat(${inclusion},${person_id}) ;;
  }
  dimension: inclusion {
    label: "Cohort Name"
    type: string
  }
  dimension: person_id {
    hidden: yes
    type: number
  }
  dimension: ordinal_rank {
    hidden: yes
    label: "Event ID"
    description: "Ordinal Rank"
    type: number
  }
  measure: count {
    hidden: yes
    type: count
  }
  measure: count_pk {
    hidden: yes
    type: count_distinct
    sql: ${pk} ;;
  }

}

## Example B: Step 1: Sizing the cohort

view: cohort_sizing {

  filter: age_filter {
    label: "Step 1: Age"
    type: number
  }

  dimension: is_age_filter {
    hidden: yes
    type: yesno
    sql:  {% condition age_filter %} ${person.age} {% endcondition %}  ;;
  }

  filter: gender_filter {
    label: "Step 2: Gender"
    type: string
    suggest_explore: condition_occurrence
    suggest_dimension: person.gender_source_value
  }

  dimension: is_gender_filter {
    hidden: yes
    type: yesno
    sql:  {% condition gender_filter %} ${person.gender_source_value} {% endcondition %}  ;;
  }

  filter: region_filter {
    label: "Step 3: Region"
    type: string
    suggest_explore: condition_occurrence
    suggest_dimension: location.region
  }

  dimension: is_region_filter {
    hidden: yes
    type: yesno
    sql:  {% condition region_filter %} ${location.region} {% endcondition %}  ;;
  }

  filter: condition_filter {
    label: "Step 4: Condition"
    type: string
    suggest_explore: condition_occurrence
    suggest_dimension: concept.concept_name
  }

  dimension: is_condition_filter {
    hidden: yes
    type: yesno
    sql:  {% condition condition_filter %} ${concept.concept_name} {% endcondition %}  ;;
  }

  measure: count_patients_step_0 {
    label: "Patients (0: Start)"
    type: count_distinct
    sql: ${condition_occurrence.person_id} ;;
  }

  measure: count_patients_step_1 {
    label: "Patients (1: Age)"
    type: count_distinct
    sql: ${condition_occurrence.person_id} ;;
    filters: [is_age_filter: "Yes"]
  }

  measure: count_patients_step_2 {
    label: "Patients (2: Gender)"
    type: count_distinct
    sql: ${condition_occurrence.person_id} ;;
    filters: [
      is_age_filter: "Yes",
      is_gender_filter: "Yes"
    ]
  }

  measure: count_patients_step_3 {
    label: "Patients (3: Region)"
    type: count_distinct
    sql: ${condition_occurrence.person_id} ;;
    filters: [
      is_age_filter: "Yes",
      is_gender_filter: "Yes",
      is_region_filter: "Yes"
    ]
  }

  measure: count_patients_step_4 {
    label: "Patients (4: Condition)"
    type: count_distinct
    sql: ${condition_occurrence.person_id} ;;
    filters: [
      is_age_filter: "Yes",
      is_gender_filter: "Yes",
      is_region_filter: "Yes",
      is_condition_filter: "Yes"
    ]
  }

}

## Example B: Step 2: Creating the cohort

view: type2_diabetes_men_over_65 {
  derived_table: {
    datagroup_trigger: once_weekly
    explore_source: condition_occurrence {
      column: person_id {}
      filters: {
        field: condition_occurrence.condition_start_date
        value: "2010/06/04"
      }
      filters: {
        field: person.gender_source_value
        value: "M"
      }
      filters: {
        field: location.region
        value: ""
      }
      filters: {
        field: concept.concept_name
        value: "%Type 2 diabetes%"
      }
      filters: {
        field: person.age
        value: "[65, 125]"
      }
    }
  }
  dimension: person_id {}
}

view: type2_diabetes_men_under_65 {
  derived_table: {
    datagroup_trigger: once_weekly
    explore_source: condition_occurrence {
      column: person_id {}
      filters: {
        field: condition_occurrence.condition_start_date
        value: "2010/06/04"
      }
      filters: {
        field: person.gender_source_value
        value: "M"
      }
      filters: {
        field: location.region
        value: ""
      }
      filters: {
        field: concept.concept_name
        value: "%Type 2 diabetes%"
      }
      filters: {
        field: person.age
        value: "[0, 65)"
      }
    }
  }
  dimension: person_id {}
}

view: type2_diabetes_women_over_65 {
  derived_table: {
    datagroup_trigger: once_weekly
    explore_source: condition_occurrence {
      column: person_id {}
      filters: {
        field: condition_occurrence.condition_start_date
        value: "2010/06/04"
      }
      filters: {
        field: person.gender_source_value
        value: "F"
      }
      filters: {
        field: location.region
        value: ""
      }
      filters: {
        field: concept.concept_name
        value: "%Type 2 diabetes%"
      }
      filters: {
        field: person.age
        value: "[65, 125]"
      }
    }
  }
  dimension: person_id {}
}

view: type2_diabetes_women_under_65 {
  derived_table: {
    datagroup_trigger: once_weekly
    explore_source: condition_occurrence {
      column: person_id {}
      filters: {
        field: condition_occurrence.condition_start_date
        value: "2010/06/04"
      }
      filters: {
        field: person.gender_source_value
        value: "F"
      }
      filters: {
        field: location.region
        value: ""
      }
      filters: {
        field: concept.concept_name
        value: "%Type 2 diabetes%"
      }
      filters: {
        field: person.age
        value: "[0, 65)"
      }
    }
  }
  dimension: person_id {}
}

## Example B: Step 3: Analyzing the cohort

view: cohorts_combined {
  derived_table: {
    datagroup_trigger: once_weekly
    sql:
                SELECT 'Type 2 Diabetes - Men Over 65' as cohort_name, * FROM ${type2_diabetes_men_over_65.SQL_TABLE_NAME}
      UNION ALL SELECT 'Type 2 Diabetes - Men Under 65' as cohort_name, * FROM ${type2_diabetes_men_under_65.SQL_TABLE_NAME}
      UNION ALL SELECT 'Type 2 Diabetes - Women Over 65' as cohort_name, * FROM ${type2_diabetes_women_over_65.SQL_TABLE_NAME}
      UNION ALL SELECT 'Type 2 Diabetes - Women Under 65' as cohort_name, * FROM ${type2_diabetes_women_under_65.SQL_TABLE_NAME}
    ;;
  }

  dimension: pk {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${cohort_name} || ${person_id} ;;
  }
  dimension: cohort_name {
    link: {
      label: "{{ value }} Deep Dive - Overall"
      url: "/dashboards-next/863?Cohort+Name={{ value }}"
      icon_url: "http://www.google.com/s2/favicons?domain=www.looker.com"
    }
    link: {
      label: "{{ value }} Deep Dive - Comparison"
      url: "/dashboards-next/862?Cohort+A={{ value }}"
      icon_url: "http://www.google.com/s2/favicons?domain=www.looker.com"
    }
    link: {
      label: "{{ value }} Deep Dive - Geographic Focus"
      url: "/dashboards-next/863?Cohort+Name={{ value }}"
      icon_url: "http://www.google.com/s2/favicons?domain=www.looker.com"
    }
    link: {
      label: "{{ value }} Deep Dive - Demographic Focus"
      url: "/dashboards-next/863?Cohort+Name={{ value }}"
      icon_url: "http://www.google.com/s2/favicons?domain=www.looker.com"
    }
    link: {
      label: "{{ value }} Deep Dive - Comorbidity Focus"
      url: "/dashboards-next/863?Cohort+Name={{ value }}"
      icon_url: "http://www.google.com/s2/favicons?domain=www.looker.com"
    }
    action: {
      label: "Text Team for Support"
      url: "https://desolate-refuge-53336.herokuapp.com/posts"
      icon_url: "https://www.google.com/s2/favicons?domain_url=http://www.zappier.com"
      param: {
        name: "some_auth_code"
        value: "abc123456"
      }
      form_param: {
        name: "Phone Number"
        required: yes
        default: "703-555-8240"
      }
      form_param: {
        name: "Body"
        type: textarea
        required: yes
        default:
        "Hi Ted - We had a lot of issues with your {{ value }} cohort. Please text me back ASAP."
      }
    }
    action: {
      label: "Create Support Ticket"
      url: "https://desolate-refuge-53336.herokuapp.com/posts"
      icon_url: "https://www.google.com/s2/favicons?domain_url=http://www.servicenow.com"
      param: {
        name: "some_auth_code"
        value: "abc123456"
      }
      form_param: {
        type: select
        name: "Team"
        option: {
          name: "Cohort Support"
          label: "Cohort Support"
        }
        option: {
          name: "Training Support"
          label: "Training Support"
        }
        option: {
          name: "Other"
          label: "Other"
        }
        required: yes
        default: "Cohort Support"
      }
      form_param: {
        type: select
        name: "Priority"
        option: {
          name: "P1 - High"
          label: "P1 - High"
        }
        option: {
          name: "P2 - Medium"
          label: "P2 - Medium"
        }
        option: {
          name: "P3 - Low"
          label: "P3 - Low"
        }
        required: yes
        default: "P1 - High"
      }
      form_param: {
        name: "Ticket Description"
        type: textarea
        required: yes
        default:
        "Hi IT team - We had a lot of issues with the {{ value }} cohort. It was showing errors."
      }
    }
    action: {
      label: "Edit Cohort"
      url: "https://desolate-refuge-53336.herokuapp.com/posts"
      icon_url: "https://www.google.com/s2/favicons?domain_url=http://www.looker.com"
      param: {
        name: "some_auth_code"
        value: "abc123456"
      }
      form_param: {
        type: select
        name: "Action"
        option: {
          name: "Update Cohort"
          label: "Update Cohort"
        }
        option: {
          name: "Delete Cohort"
          label: "Delete Cohort"
        }
        option: {
          name: "Other"
          label: "Other"
        }
        required: yes
        default: "Update Support"
      }
      form_param: {
        name: "Cohort Description"
        type: textarea
        required: yes
        default:
        "Pleaes update {{ value }} cohort with these changes: "
      }
    }
  }
  dimension: creator {
    group_label: "Cohort Metadata"
    type: string
    sql: '{{_user_attributes["email"]}}' ;;
  }
  dimension: create_date {
    group_label: "Cohort Metadata"
    type: date
    sql: cast(current_date() as timestamp) ;;
  }
  dimension: cohort_name_a {
    hidden: yes
    sql: ${cohort_name} ;;
  }
  dimension: cohort_name_b {
    hidden: yes
    sql: ${cohort_name} ;;
  }
  dimension: person_id {
    hidden: yes
  }

  filter: cohort_a {
    group_label: "Cohort Comparison"
    type: string
    suggest_explore: condition_occurrence
    suggest_dimension: cohorts_combined.cohort_name_a
  }

  filter: cohort_b {
    group_label: "Cohort Comparison"
    type: string
    suggest_explore: condition_occurrence
    suggest_dimension: cohorts_combined.cohort_name_b
  }

  dimension: is_cohort_a {
    hidden: yes
    type: yesno
    sql:  {% condition cohort_a %} ${cohorts_combined.cohort_name} {% endcondition %}  ;;
  }

  dimension: is_cohort_b {
    hidden: yes
    type: yesno
    sql:  {% condition cohort_b %} ${cohorts_combined.cohort_name} {% endcondition %}  ;;
  }

  measure: count_patients {
    type: count_distinct
    sql: ${person_id} ;;
    drill_fields: [drill*]
  }

  measure: percent_patients {
    type: number
    sql: 1.0 * ${count_patients} / nullif(${cohort_sizes.sum_count_patients},0) ;;
    value_format_name: percent_1
    drill_fields: [drill*]
  }

  measure: count_patients_cohort_a {
    group_label: "Cohort Comparison"
    type: count_distinct
    sql: ${person_id} ;;
    filters: [is_cohort_a: "Yes"]
    drill_fields: [drill*]
  }

  measure: count_patients_cohort_b {
    group_label: "Cohort Comparison"
    type: count_distinct
    sql: ${person_id} ;;
    filters: [is_cohort_b: "Yes"]
    drill_fields: [drill*]
  }

  measure: percent_patients_cohort_a {
    group_label: "Cohort Comparison"
    type: number
    sql: 1.0 * ${count_patients_cohort_a} / nullif(${cohort_sizes.sum_count_patients_cohort_a},0) ;;
    value_format_name: percent_1
    drill_fields: [drill*]
  }

  measure: percent_patients_cohort_b {
    group_label: "Cohort Comparison"
    type: number
    sql: 1.0 * ${count_patients_cohort_b} / nullif(${cohort_sizes.sum_count_patients_cohort_b},0) ;;
    value_format_name: percent_1
    drill_fields: [drill*]
  }

  set: drill {
    fields: [
      person.person_id,
      person.age,
      person.gender_source_value,
      location.region,
      concept.concept_name
    ]
  }
}

view: cohort_sizes {
  derived_table: {
    explore_source: condition_occurrence {
      bind_all_filters: yes
      column: cohort_name { field: cohorts_combined.cohort_name }
      column: count_patients { field: cohorts_combined.count_patients }
      column: count_patients_cohort_a { field: cohorts_combined.count_patients_cohort_a }
      column: count_patients_cohort_b { field: cohorts_combined.count_patients_cohort_b }
      filters: {
        field: condition_occurrence.condition_start_date
        value: "2010/06/04"
      }
    }
  }
  dimension: cohort_name {
    primary_key: yes
    hidden: yes
  }
  dimension: count_patients { hidden: yes }
  dimension: count_patients_cohort_a { hidden: yes }
  dimension: count_patients_cohort_b { hidden: yes }
  measure: sum_count_patients { hidden: yes type: sum sql: ${cohort_sizes.count_patients} ;;}
  measure: sum_count_patients_cohort_a { hidden: yes type: sum sql: ${cohort_sizes.count_patients_cohort_a} ;;}
  measure: sum_count_patients_cohort_b { hidden: yes type: sum sql: ${cohort_sizes.count_patients_cohort_b} ;;}
}
