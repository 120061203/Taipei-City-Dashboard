from operators.common_pipeline import CommonDag


def _transfer(**kwargs):
    import ssl
    import urllib.request
    import pandas as pd
    from io import StringIO
    from sqlalchemy import create_engine
    from utils.load_stage import (
        save_dataframe_to_postgresql,
        update_lasttime_in_data_to_dataset_info,
    )
    from utils.get_time import get_tpe_now_time_str

    # Config
    ready_data_db_uri = kwargs.get("ready_data_db_uri")
    dag_infos = kwargs.get("dag_infos")
    dag_id = dag_infos.get("dag_id")
    load_behavior = dag_infos.get("load_behavior")
    default_table = dag_infos.get("ready_data_default_table")
    history_table = dag_infos.get("ready_data_history_table")

    # Extract — 繞過 TWCA 憑證的 Subject Key Identifier 問題（政府網站已知問題）
    URL = (
        "https://tsis.dbas.gov.taipei/statis/webMain.aspx"
        "?sys=220&ymf=5900&kind=21&type=0&funid=a05031801"
        "&cycle=4&outmode=12&compmode=0&outkind=1&deflst=2&nzo=1"
    )
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    with urllib.request.urlopen(URL, context=ctx) as resp:
        raw_data = pd.read_csv(StringIO(resp.read().decode("utf-8-sig")))

    # Transform
    data = raw_data.copy()
    column_mapping = {}
    for col in data.columns:
        if "統計期" in col:
            column_mapping[col] = "year"
        elif "不合格飭令改善家次" in col and "/" not in col:
            column_mapping[col] = "non_compliant_visits"
        elif "稽查家次" in col and "/" not in col:
            column_mapping[col] = "inspection_visits"
        elif "食品中毒人數" in col:
            column_mapping[col] = "food_poisoning_cases"
    data = data.rename(columns=column_mapping)

    # 只保留需要的欄位
    data = data[["year", "inspection_visits", "non_compliant_visits", "food_poisoning_cases"]].copy()

    # 民國年 → 西元年（去除非數字字元後加 1911）
    data["year"] = data["year"].astype(str).str.replace(r"[^\d]", "", regex=True).astype(int) + 1911

    data = data.dropna()
    data["inspection_visits"] = pd.to_numeric(data["inspection_visits"], errors="coerce").fillna(0).astype(int)
    data["non_compliant_visits"] = pd.to_numeric(data["non_compliant_visits"], errors="coerce").fillna(0).astype(int)
    data["food_poisoning_cases"] = pd.to_numeric(data["food_poisoning_cases"], errors="coerce").fillna(0).astype(int)
    data["data_time"] = get_tpe_now_time_str(is_with_tz=True)

    # Load
    engine = create_engine(ready_data_db_uri)
    save_dataframe_to_postgresql(
        engine,
        data=data,
        load_behavior=load_behavior,
        default_table=default_table,
        history_table=history_table,
    )
    update_lasttime_in_data_to_dataset_info(engine, dag_id, data["data_time"].max())


dag = CommonDag(
    proj_folder="proj_city_dashboard",
    dag_folder="food_hygiene_management_work",
)
dag.create_dag(etl_func=_transfer)
