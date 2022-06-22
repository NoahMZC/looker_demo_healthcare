view: location {
  sql_table_name: `lookerdata.cms_synthetic_patient_data_omop.location`
    ;;
  drill_fields: [location_id]

  dimension: location_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.location_id ;;
  }

  dimension: address_1 {
    type: string
    sql: ${TABLE}.address_1 ;;
  }

  dimension: address_2 {
    type: string
    sql: ${TABLE}.address_2 ;;
  }

  dimension: city {
    type: string
    sql: ${TABLE}.city ;;
    drill_fields: [county, zip]
  }

  dimension: county {
    type: string
    sql: ${TABLE}.county ;;
    drill_fields: [city, zip]
  }

  dimension: location_source_value {
    type: string
    sql: ${TABLE}.location_source_value ;;
  }

  dimension: state {
    map_layer_name: us_states
    type: string
    sql: ${TABLE}.state ;;
    drill_fields: [zip, city, county, person.age_tiers]
  }

  dimension: region {
    type: string
    case: {
      when: {
        sql: ${state} in ('WA','OR','CA','NV','UT','WY','ID','MT','CO','AK','HI') ;;
        label: "West"
      }
      when: {
        sql: ${state} in ('AZ','NM','TX','OK') ;;
        label: "Southwest"
      }
      when: {
        sql: ${state} in ('ND','SD','MN','IA','WI','MN','OH','IN','MO','NE','KS','MI','IL') ;;
        label: "Midwest"
      }
      when: {
        sql: ${state} in ('MD','DE','NJ','CT','RI','MA','NH','PA','NY','VT','ME','DC') ;;
        label: "Northeast"
      }
      when: {
        sql: ${state} in ('AR','LA','MS','AL','GA','FL','SC','NC','VA','TN','KY','WV') ;;
        label: "Southeast"
      }
      else: "Unknown"
    }
    drill_fields: [state, zip, county, city, person.age_tiers]
  }

  dimension: zip {
    map_layer_name: us_zipcode_tabulation_areas
    type: zipcode
    sql: ${TABLE}.zip ;;
    drill_fields: [city, county]
  }

  measure: count {
    type: count
    drill_fields: [location_id, person.count]
  }
}
