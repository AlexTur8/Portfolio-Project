import os
from catboost import CatBoost
from catboost import CatBoostClassifier
import pandas as pd
from sqlalchemy import create_engine
from typing import List
from fastapi import FastAPI
from schema import PostGet
from datetime import datetime
from pydantic import BaseModel

import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from collections import Counter
import string
from sklearn.decomposition import PCA


app = FastAPI()

class PostGet(BaseModel):
    id: int
    text: str
    topic: str

    class Config:
        orm_mode = True


def get_model_path(path: str) -> str:
    if os.environ.get("IS_LMS") == "1":  # проверяем где выполняется код в лмс, или локально. Немного магии
        MODEL_PATH = '/workdir/user_input/model'
    else:
        MODEL_PATH = path
    return MODEL_PATH

def load_models():
    model_path = get_model_path("catboost_model")
    model = CatBoost().load_model(model_path)
    return model


def save_to_database(data: pd.DataFrame):
    # Создаем соединение с базой данных
    engine = create_engine(
        "postgresql://robot-startml-ro:pheiph0hahj1Vaif@"
        "postgres.lab.karpov.courses:6432/startml"
    )
    
    # Записываем данные в базу данных
    data.to_sql(name='a_tursina_features_lesson_22', con=engine, if_exists='replace', index=False)
    
    print(f"Данные успешно записаны в таблицу a_tursina_features_lesson_22 в базу данных.")



def batch_load_sql(query: str) -> pd.DataFrame:
    CHUNKSIZE = 20000
    engine = create_engine(
        "postgresql://robot-startml-ro:pheiph0hahj1Vaif@"
        "postgres.lab.karpov.courses:6432/startml"
    )
    conn = engine.connect().execution_options(stream_results=True)
    chunks = []
    for chunk_dataframe in pd.read_sql(query, conn, chunksize=CHUNKSIZE):
        chunks.append(chunk_dataframe)
    conn.close()
    return pd.concat(chunks, ignore_index=True)




def load_features() -> pd.DataFrame:   # функция, которая бы загружала признаки с помощью функции batch_load_sql

    query = 'SELECT * FROM "a_tursina_features_lesson_22"'
    data = batch_load_sql(query)
    return data


# загружайте признаки и модель вне endpoint
model = load_models()
df_features = load_features() 

df_post = batch_load_sql('SELECT * FROM public.post_text_df')


def generate_posts(top_posts, df_post, limit):
    for post_id in top_posts[:limit]:
        post_data = df_post[df_post['post_id'] == post_id]
        if not post_data.empty:
            text = post_data['text'].values[0]
            topic = post_data['topic'].values[0]
            yield PostGet(id=post_id, text=text, topic=topic)

@app.get("/post/recommendations/", response_model=List[PostGet])
def recommended_posts(
        id: int,
        time: datetime,
        limit: int = 5) -> List[PostGet]:
    # Отбор признаков для конкретного user_id
    user_features = df_features[df_features['user_id'] == id]

    # Прогноз
    # Получение предсказанных значений
# Получение предсказанных значений
    user_pred = model.predict(user_features)

# Преобразование предсказанных значений в вероятности с помощью сигмоидной функции
    user_pred_proba = 1 / (1 + np.exp(-user_pred))

    top_posts = user_features['post_id'].iloc[np.argsort(user_pred_proba)[::-1]].tolist()


    # Возвращаем ТОП-5 постов
    result = generate_posts(top_posts, df_post, limit)

    return list(result)
