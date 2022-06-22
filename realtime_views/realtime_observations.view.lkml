include: "/simplified_views/*"
# include: "/demo_vitals/*"

view: realtime_observations {
  sql_table_name: `mzcdsc-team-200716.Looker_Demo_healthcare_demo_live.realtime_observation` ;;
  extends: [observation_vitals]
}
