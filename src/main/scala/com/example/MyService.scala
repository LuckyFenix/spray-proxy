package com.example

import akka.actor.{Actor, ActorSystem}
import spray.routing._
import spray.http._
import spray.httpx.SprayJsonSupport._
import MediaTypes._
import akka.pattern.ask
import akka.io.IO
import akka.util.Timeout
import spray.can.Http
import spray.can.Http.ClientConnectionType
import spray.json._
import spray.json.DefaultJsonProtocol
import spray.client.pipelining._
import spray.util.LoggingContext

import scala.concurrent.Future
import scala.concurrent.Future.{successful => future}
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

// we don't implement our route structure directly in the service actor because
// we want to be able to test it independently, without having to spin up an actor
class MyServiceActor extends Actor with MyService {

  // the HttpService trait defines only one abstract member, which
  // connects the services environment to the enclosing actor or test
  implicit def actorRefFactory = context

  // this actor only runs our route, but you could add
  // other things here, like request stream processing
  // or timeout handling
  def receive = runRoute(myRoute)
}


// this trait defines our service behavior independently from the service actor
trait MyService extends HttpService {
  this: MyServiceActor =>

  case class User(name: String, age: Int)

  case class UserWF(name: String, age: Int, friends: List[User])

  object MyJsonProtocol extends DefaultJsonProtocol {
    implicit val userFormat = jsonFormat2(User)
    implicit val userWFFormat = jsonFormat3(UserWF)
  }

  implicit val system = context.system
  implicit val timeout = Timeout(20.seconds)

  import MyJsonProtocol._


  val myRoute =
    path("") {
      get {
        parameter('proxy, 'port.as[Int], 'url) { case (proxy, port, url) =>
          val pipeline: Future[SendReceive] =
            for (
              Http.HostConnectorInfo(connector, _) <-
              IO(Http) ? Http.HostConnectorSetup(
                "0.0.0.0",
                port = 80,
                connectionType = ClientConnectionType.Proxied(proxy, port)
              )
            ) yield sendReceive(connector)

          val response: Future[HttpResponse] = pipeline.flatMap(_(Get(url)))

          onComplete(response) {
            case Success(v) => complete(v)
            case Failure(e) => complete("error")
          }
        }
      }
    }
}